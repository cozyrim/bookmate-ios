"""Create non-production configuration for a clean CI checkout."""
import pathlib
import plistlib

root = pathlib.Path(__file__).resolve().parents[2]
local = root / '.local'
local.mkdir(exist_ok=True)
(local / 'Secrets.xcconfig').write_text(
    'KAKAO_NATIVE_APP_KEY = ci-placeholder\n'
    'BOOKMATE_API_ENVIRONMENT = local\n'
)
with (root / 'GoogleService-Info.plist').open('wb') as file:
    plistlib.dump({
        'API_KEY': 'AIzaSy' + '0' * 33,
        'GCM_SENDER_ID': '123456789012',
        'PLIST_VERSION': '1',
        'BUNDLE_ID': 'cozyrim.BookMate-mini',
        'PROJECT_ID': 'bookmate-ci',
        'STORAGE_BUCKET': 'bookmate-ci.appspot.com',
        'IS_ADS_ENABLED': False,
        'IS_ANALYTICS_ENABLED': False,
        'IS_APPINVITE_ENABLED': False,
        'IS_GCM_ENABLED': False,
        'IS_SIGNIN_ENABLED': False,
        'GOOGLE_APP_ID': '1:123456789012:ios:0123456789abcdef012345',
    }, file)
