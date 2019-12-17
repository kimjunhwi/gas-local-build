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
  if ["pledis","bts","smtown","ssm","ssm","ssp" ].include?(title) == false
    puts "please insert title name { smtown , pledis , bts , ssm , ssp , ssb} \n example: ruby gas.rb pledis"

      return
  end

  parameters = [title]
  request = Google::Apis::ScriptV1::ExecutionRequest.new(
    function: 'GetIOSdata', parameters: parameters
  )
  response = script_service.run_script(SCRIPT_ID, request).response

  result = response['result']

  ios_create_skuFile(result['ios'],title)
  android_create_skuFile(result,title)

end

def android_create_skuFile(skuList,title)
  
  data = skuList['androidSkuData']
  tierData = skuList['androidStoreTier']

  resultData = ""
  resultData << "Product ID,Published State,Purchase Type,Auto Translate,Locale; Title; Description,Auto Fill Prices,Price,Pricing Template ID\r\n"

  data.each do |arrayData|
    if arrayData[AppleEnum::E_REGISTER] == true && arrayData[AppleEnum::E_REQUEST] == false
      resultData << arrayData[AndroidEnum::E_PRODUCT] + ",";
      resultData << "published,";
      resultData << "managed_by_android,";
      resultData << "false,";
      resultData << "ja_JP;";
      resultData << arrayData[AndroidEnum::E_NAME] +";";
      resultData << arrayData[AndroidEnum::E_EXPLAIN_JP]+";";
      resultData << "zh_TW;"
      resultData << arrayData[AndroidEnum::E_NAME]+";";
      resultData << arrayData[AndroidEnum::E_EXPLAIN_TW]+",";
      resultData << "false,,";

      tierData.each do |key, value|
        if key == arrayData[AndroidEnum::E_PRICE]
          resultData << value + "\n"
          break
        end
      end
    end
  end

  time = Time.new

  fileName = "Android_#{title}#{time.strftime("_%m-%d_%H-%M-%S")}.csv"

  file = File.new(fileName,"w")

  file.syswrite(resultData)

end

def ios_create_skuFile(skulist,title)
  
  resultHash = []

  skulist.each do |arrayData|
    if arrayData[0] == true && arrayData[1] == false
      hash = Hash.new

      hash['product_id'] = arrayData[AppleEnum::E_PRODUCT];
      hash['reference_name'] = arrayData[AppleEnum::E_REFERENCE];
      hash['tier'] = arrayData[AppleEnum::E_TIER];
      hash['name'] = arrayData[AppleEnum::E_SHOW_NAME];
      hash['description_JP'] = arrayData[AppleEnum::E_EXPLAIN_JP];
      hash['description_TW'] = arrayData[AppleEnum::E_EXPLAIN_TW];
      hash['review_screenshot'] = "inapppurchase/" + (arrayData[AppleEnum::E_PRICE].delete "￥") + ".png";
      hash['review_notes'] = arrayData[AppleEnum::E_REVIEW_NOTES];

      resultHash.push(hash)
    end
  end

  time = Time.new

  fileName = "iOS_#{title}#{time.strftime("_%m-%d_%H-%M-%S")}.json"

  file = File.new(fileName,"w")

  file.syswrite(resultHash.to_json)
end

run_script(ARGV[0])



# //CSVデータ形式に整える関数
# function csvchange(data,storeIdData){
#   var rowlength = data.length;
#   var csvdata = "";
#   var csv = "";
  
#   csvdata += "Product ID,Published State,Purchase Type,Auto Translate,Locale; Title; Description,Auto Fill Prices,Price,Pricing Template ID\r\n";
  
#   for(var i = 0;i<rowlength -3;i++){
#     if(data[i][AndroidEnum.E_TIER] == null)
#         continue;
        
#     if(data[i][AppleEnum.E_REGISTER] == (data[i][AppleEnum.E_REQUEST] == false))
#     {
#     csvdata += data[i][AndroidEnum.E_PRODUCT] + ",";
#     csvdata += "published,";
#     csvdata += "managed_by_android,";
#     csvdata += "false,";
#     csvdata += "ja_JP;";
#     csvdata += data[i][AndroidEnum.E_NAME] +";";
#     csvdata += data[i][AndroidEnum.E_EXPLAIN_JP]+";";
#     csvdata += "zh_TW;"
#     csvdata += data[i][AndroidEnum.E_NAME]+";";
#     csvdata += data[i][AndroidEnum.E_EXPLAIN_TW]+",";
#     csvdata += "false,,";
    
#     for(var index = 0; index < storeIdData.length; index++)
#     {
#       if(storeIdData[index][0] == data[i][AndroidEnum.E_PRICE])
#       {
#         csvdata += storeIdData[index][1];
#         break;
#       }
#     }
#     csvdata += "\r\n";
#     }
#   }
 
#   return csvdata;
# }