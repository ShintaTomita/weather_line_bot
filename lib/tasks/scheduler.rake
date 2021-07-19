desc "Thid task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  #使用したxmlデータ(毎日朝６時更新) :以下URLを入力すれば見る事が出来る
  url = "https://www.drk7.jp/weather/xml/28.xml"
  #xmlデータをパース
  xml = open( url ).read.toutf8
  doc = REXML::Document.new(xml)
  #パスの共通部分を変化化(area[2]は兵庫県南部を示している)
  xpath = 'weatherforecast/pref/area[2]/info/rainfallchance/'
  #6~12時の降水確率
  per06to12 = doc.elements[xpath + 'period[2]'].text
  per12to18 = doc.elements[xpath + 'period[3]'].text
  per18to24 = doc.elements[xpath + 'period[4]'].text
  #メッセージを発信する降水確率の下限値の設定
  min_per = 20
  if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
    word1 =
      ["いい朝ですね！",
       "よく寝れましたか？",
       "おはよう！！",
       "Hey！、調子はどう？"].sample
    word2 =
      ["お気をつけて",
       "Have a nice day",
       "今日も一日頑張っていこう",
       "楽しい事がありますように！",
       "今度の休みは何をしようかな"].sample
    min_per = 50
    if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
      word3 = "今日は雨が降りそうだから傘を持っていった方がいいよ！"
    else
      word3 = "今日は雨が降るかもしれないから折り畳み傘があると安心ですよ！"
    end
    #発信するメッセージ
    push =
      "#{word1}\n#{word3}\n降水確率はこんな感じだよ。\n    6〜12時 #{per06to12}%\n
      12〜18時　　#{per12to18}%\n 18〜24時   #{per12to18}%\n#{word2}"
    #　メッセージの発信先idを配列で渡す必要がある為、userテーブルよりpluck関数を使ってidを配列で取得
    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
  end
  "OK"
end
