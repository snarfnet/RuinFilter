import hashlib
import os
import sys
import time

import jwt
import requests

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
BUNDLE_ID = 'com.tokyonasu.ruinfilter'
APP_VERSION = '1.0.1'
BUILD_NUMBER = sys.argv[1]
SCREENSHOT_DIR = 'screenshots/appstore'

SCREENSHOT_GROUPS = [
    ('APP_IPHONE_67', ['iphone_1_home.png', 'iphone_2_editor.png', 'iphone_3_result.png']),
    ('APP_IPAD_PRO_3GEN_129', ['ipad_1_home.png', 'ipad_2_editor.png', 'ipad_3_result.png']),
]

WHATS_NEW = {
    'ja': 'デザインを大幅に刷新し、より怖い廃墟ホラー風のUIに変更しました。文字の読みやすさ、操作ボタン、フィルター選択画面も改善しています。',
    'en-US': 'Refreshed the app with a darker haunted-ruin visual design, improved readability, clearer controls, and updated screenshots.',
}

p8 = open('/tmp/asc_key.p8').read()


def make_token():
    return jwt.encode(
        {'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        p8, algorithm='ES256', headers={'kid': KEY_ID}
    )


def headers():
    return {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json'}


def api(method, path, **kwargs):
    return requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}', headers=headers(), **kwargs)


def api_json(method, path, **kwargs):
    r = api(method, path, **kwargs)
    try:
        body = r.json()
    except Exception:
        body = {}
    return r, body


def list_all(path):
    all_data = []
    next_path = path
    while next_path:
        r, body = api_json('GET', next_path)
        if r.status_code != 200:
            print(f'List failed {next_path}: {r.status_code} {r.text[:500]}')
            return all_data
        all_data.extend(body.get('data', []))
        next_url = body.get('links', {}).get('next')
        next_path = next_url.split('/v1', 1)[1] if next_url else None
    return all_data


def find_app_id():
    print(f'Looking up app by bundle ID: {BUNDLE_ID}')
    r, body = api_json('GET', f'/apps?filter[bundleId]={BUNDLE_ID}')
    if not body.get('data'):
        print(f'App not found for bundle ID {BUNDLE_ID}.')
        sys.exit(1)
    app_id = body['data'][0]['id']
    print(f'App ID: {app_id}')
    return app_id


def find_or_create_version(app_id):
    versions = list_all(f'/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=200')
    for version in versions:
        attrs = version.get('attributes', {})
        if attrs.get('versionString') == APP_VERSION:
            version_id = version['id']
            state = attrs.get('appStoreState')
            print(f'Found version {APP_VERSION}: {version_id} state={state}')
            return version_id, state

    print(f'Creating new version {APP_VERSION}...')
    r, body = api_json('POST', '/appStoreVersions', json={
        'data': {
            'type': 'appStoreVersions',
            'attributes': {'platform': 'IOS', 'versionString': APP_VERSION},
            'relationships': {'app': {'data': {'type': 'apps', 'id': app_id}}}
        }
    })
    if r.status_code not in (200, 201):
        print(f'Failed to create version: {r.status_code} {r.text[:1000]}')
        sys.exit(1)
    version_id = body['data']['id']
    print(f'Created version {APP_VERSION}: {version_id}')
    return version_id, 'PREPARE_FOR_SUBMISSION'


def wait_for_build(app_id):
    print(f'Waiting for build {BUILD_NUMBER} to be processed...')
    for i in range(80):
        r, body = api_json('GET', f'/builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1')
        if body.get('data'):
            build_id = body['data'][0]['id']
            print(f'Build ready: {build_id}')
            return build_id
        print(f'  Waiting... ({i + 1}/80)')
        time.sleep(30)
    print('Build was not processed in time.')
    sys.exit(1)


def set_export_compliance(build_id):
    r = api('PATCH', f'/builds/{build_id}', json={
        'data': {'type': 'builds', 'id': build_id, 'attributes': {'usesNonExemptEncryption': False}}
    })
    print(f'Export compliance: {r.status_code}')


def update_version_localizations(version_id):
    print('Updating version release notes...')
    locs = list_all(f'/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200')
    for loc in locs:
        loc_id = loc['id']
        locale = loc['attributes'].get('locale', 'unknown')
        whats_new = WHATS_NEW.get(locale, WHATS_NEW['en-US'])
        r = api('PATCH', f'/appStoreVersionLocalizations/{loc_id}', json={
            'data': {'type': 'appStoreVersionLocalizations', 'id': loc_id, 'attributes': {'whatsNew': whats_new}}
        })
        print(f'  Release notes {locale}: {r.status_code}')


def delete_existing_screenshots(set_id):
    screenshots = list_all(f'/appScreenshotSets/{set_id}/appScreenshots?limit=200')
    for screenshot in screenshots:
        r = api('DELETE', f'/appScreenshots/{screenshot["id"]}')
        print(f'      Delete old screenshot {screenshot["id"]}: {r.status_code}')


def upload_one_screenshot(set_id, filepath, filename):
    filesize = os.path.getsize(filepath)
    checksum = hashlib.md5(open(filepath, 'rb').read()).hexdigest()
    r, body = api_json('POST', '/appScreenshots', json={
        'data': {
            'type': 'appScreenshots',
            'attributes': {'fileName': filename, 'fileSize': filesize},
            'relationships': {'appScreenshotSet': {'data': {'type': 'appScreenshotSets', 'id': set_id}}}
        }
    })
    if r.status_code not in (200, 201):
        print(f'      Reserve {filename}: FAILED {r.status_code} {r.text[:500]}')
        return False

    ss_data = body['data']
    ss_id = ss_data['id']
    upload_ops = ss_data['attributes']['uploadOperations']
    print(f'      Reserved {filename}: {ss_id} ({len(upload_ops)} parts)')

    with open(filepath, 'rb') as f:
        file_data = f.read()

    for op in upload_ops:
        op_headers = {h['name']: h['value'] for h in op['requestHeaders']}
        chunk = file_data[op['offset']:op['offset'] + op['length']]
        pr = requests.put(op['url'], headers=op_headers, data=chunk)
        print(f'        Upload part: {pr.status_code}')
        if pr.status_code not in (200, 201):
            return False

    source_checksum = ss_data['attributes'].get('sourceFileChecksum') or checksum
    for attempt in range(12):
        r = api('PATCH', f'/appScreenshots/{ss_id}', json={
            'data': {'type': 'appScreenshots', 'id': ss_id, 'attributes': {'uploaded': True, 'sourceFileChecksum': source_checksum}}
        })
        print(f'      Commit {filename} attempt {attempt + 1}/12: {r.status_code}')
        if r.status_code == 200:
            return True
        time.sleep(10)
    print(f'      Commit failed for {filename}: {r.text[:500]}')
    return False


def upload_screenshots(version_id):
    print('Replacing screenshots...')
    locs = list_all(f'/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200')
    for loc in locs:
        locale = loc['attributes'].get('locale', 'unknown')
        loc_id = loc['id']
        print(f'  Locale: {locale}')
        sets = list_all(f'/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?limit=200')
        existing_sets = {s['attributes']['screenshotDisplayType']: s['id'] for s in sets}

        for display_type, filenames in SCREENSHOT_GROUPS:
            if display_type in existing_sets:
                set_id = existing_sets[display_type]
            else:
                r, body = api_json('POST', '/appScreenshotSets', json={
                    'data': {
                        'type': 'appScreenshotSets',
                        'attributes': {'screenshotDisplayType': display_type},
                        'relationships': {'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': loc_id}}}
                    }
                })
                if r.status_code not in (200, 201):
                    print(f'    Create set {display_type}: FAILED {r.status_code} {r.text[:500]}')
                    continue
                set_id = body['data']['id']

            print(f'    Display: {display_type} set={set_id}')
            delete_existing_screenshots(set_id)
            for filename in filenames:
                filepath = os.path.join(SCREENSHOT_DIR, filename)
                if not os.path.exists(filepath):
                    print(f'      Missing {filepath}')
                    sys.exit(1)
                if not upload_one_screenshot(set_id, filepath, filename):
                    sys.exit(1)


def assign_build(version_id, build_id):
    r = api('PATCH', f'/appStoreVersions/{version_id}/relationships/build', json={'data': {'type': 'builds', 'id': build_id}})
    print(f'Build assigned: {r.status_code}')


def get_submission_items(submission_id):
    r, body = api_json('GET', f'/reviewSubmissions/{submission_id}/items?limit=200')
    if r.status_code != 200:
        print(f'List items for {submission_id} failed: {r.status_code} {r.text[:300]}')
        return []
    return body.get('data', [])


def find_reusable_submission(app_id):
    r, body = api_json('GET', f'/apps/{app_id}/reviewSubmissions?filter[state]=READY_FOR_REVIEW&limit=200')
    if r.status_code != 200:
        return None
    for sub in body.get('data', []):
        sid = sub['id']
        attrs = sub.get('attributes', {})
        items = get_submission_items(sid)
        print(f'Reusable candidate {sid}: submittedDate={attrs.get("submittedDate")} items={len(items)}')
        if not attrs.get('submittedDate') and not items:
            return sid
    return None


def submit_for_review(app_id, version_id):
    submission_id = find_reusable_submission(app_id)
    if submission_id:
        print(f'Reusing empty ReviewSubmission: {submission_id}')
    else:
        r, body = api_json('POST', '/reviewSubmissions', json={
            'data': {'type': 'reviewSubmissions', 'relationships': {'app': {'data': {'type': 'apps', 'id': app_id}}}}
        })
        if r.status_code != 201:
            print(f'Create reviewSubmission failed: {r.status_code} {r.text[:2000]}')
            sys.exit(1)
        submission_id = body['data']['id']
        print(f'ReviewSubmission created: {submission_id}')

    item_added = False
    for attempt in range(20):
        r = api('POST', '/reviewSubmissionItems', json={
            'data': {
                'type': 'reviewSubmissionItems',
                'relationships': {
                    'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': submission_id}},
                    'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version_id}}
                }
            }
        })
        print(f'Add item attempt {attempt + 1}/20: {r.status_code}')
        if r.status_code == 201:
            item_added = True
            break
        time.sleep(30)
    if not item_added:
        print(f'Failed to add item: {r.text[:2000]}')
        sys.exit(1)

    r, body = api_json('PATCH', f'/reviewSubmissions/{submission_id}', json={
        'data': {'type': 'reviewSubmissions', 'id': submission_id, 'attributes': {'submitted': True}}
    })
    if r.status_code == 200:
        print(f'Submitted! State: {body["data"]["attributes"]["state"]}')
    else:
        print(f'Submit failed: {r.status_code} {r.text[:2000]}')
        sys.exit(1)


app_id = find_app_id()
version_id, version_state = find_or_create_version(app_id)
if version_state in ('WAITING_FOR_REVIEW', 'IN_REVIEW'):
    print(f'Version {APP_VERSION} already in review ({version_state}). Nothing to do.')
    sys.exit(0)

build_id = wait_for_build(app_id)
set_export_compliance(build_id)
update_version_localizations(version_id)
upload_screenshots(version_id)
print('Waiting for App Store Connect to finish screenshot processing...')
time.sleep(300)
assign_build(version_id, build_id)
submit_for_review(app_id, version_id)
