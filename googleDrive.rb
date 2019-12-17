require 'json'
require 'timeout'
require 'fileutils'

require 'google/apis/script_v1'
require 'google/apis/storage_v1beta2'
require 'googleauth'
require 'googleauth/stores/file_token_store'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Google Apps Script'.freeze
CLIENT_SECRETS_PATH = './client_secrets.json'.freeze
CREDENTIALS_PATH='./gas_token.yaml'
SCOPE = ['https://www.googleapis.com/auth/spreadsheets']
SCRIPT_ID = 'MLTWa0Yt97HJoSeI7ExP6-B3i-4C3PvaK'.freeze


module AppleEnum
    E_REGISTER  = 0
    E_REQUEST   = 1
    E_PRODUCT   = 4
    E_REFERENCE = 5
    E_TIER      = 6
    E_PRICE     = 7
    E_SHOW_NAME = 8
    E_EXPLAIN_JP = 9
    E_EXPLAIN_TW = 10
    E_SCRINSHOT_URL = 11
    E_REVIEW_NOTES =12
end

module AndroidEnum
      E_PRODUCT     = 4
      E_NAME        = 5
      E_EXPLAIN_JP  = 6
      E_EXPLAIN_TW  = 7
      E_PRICE       = 8
      E_TIER        = 9
end

def credentials
  client_secrets = JSON.parse(File.read(CLIENT_SECRETS_PATH))
  client_id = Google::Auth::ClientId.from_hash(client_secrets)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  Google::Apis::RequestOptions.default.retries = 5
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts 'Open the following URL in the browser and enter the ' \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

def script_service
  service = Google::Apis::ScriptV1::ScriptService.new
  service.authorization = credentials
  service
end

def run_script(title)

end

run_script(ARGV[0])