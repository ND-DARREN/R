#----------------店铺数据更新------------------------
require(RSelenium)
require(RODBC)
require(readxl)
require(rvest)
require(httr)
require(stringr)
require(readr)
require(xlsx)
require(dplyr)
library(XML)
require(lubridate)#用于日期:days_in_month
rm(list=ls())
zydb_dir <- '//192.168.1.11/data/直营.accdb' #zydb_dir直营数据库地址
setwd('C:\\Users\\hanhoo\\Downloads')
Rfile <- '\\\\192.168.1.11\\data\\spider_day\\'
file.remove(paste('C:\\Users\\hanhoo\\Downloads\\',list.files('C:\\Users\\hanhoo\\Downloads\\'),sep=''))
##----------------打开浏览器并登陆淘宝--------------------
b <- remoteDriver(remoteServerAddr = "localhost",port = 4444,browserName = "chrome",extraCapabilities=list(chromeOptions=list(args=list('--always-authorize-plugins=true','start-maximized=true'))))
b$open(silent = T)

#如果是扫码登录切换成密码登录
b$navigate('https://login.taobao.com/member/login.jhtml?')
Sys.sleep(0.5)
repeat{
  if(b$findElement(using='css selector',value='#J_QRCodeLogin > div.login-title')$getElementText()[[1]]=='手机扫码，安全登录'){b$findElement('css selector', '#J_Quick2Static')$clickElement()} 
  if(b$findElement(using='css selector',value='#J_StaticForm > div')$getElementText()[[1]]=='密码登录'){break()}
}

b$findElement(using='css selector', value='#TPL_username_1')$sendKeysToElement(list(iconv("hanhoo韩后旗舰店",from='gbk',to='utf8')))
b$findElement(using='css selector', value='#TPL_password_1')$sendKeysToElement(list("#@Hanhoo66235885"))
# b$findElement('css selector', '#J_SubmitStatic')$clickElement() 点击登录（一般情况手动点，自动执行容易出现验证）

#获取token
b$navigate('https://sycm.taobao.com/adm/v2/my')
pagesource <- unlist(b$findElement(using='css selector', 'head > meta:nth-child(9)')$getElementAttribute("content"))
Token <- substring(pagesource , regexpr("Token=", pagesource)+6, regexpr("Token=", pagesource)+14)

#####################################################################################################################
#####################################################################################################################

source(paste(Rfile,'sycm_basic.r',sep=''),encoding = 'utf8') #获取生意参谋自定义店铺数据 basic

source(paste(Rfile,'sycm_home.r',sep=''),encoding = 'utf8') #获取生意参谋店铺首页数据 shouye_combine

source(paste(Rfile,'sycm_product.r',sep=''),encoding = 'utf8') #获取生意参谋商品数据数据 product_res

source(paste(Rfile,'sycm_traffic.r',sep=''),encoding = 'utf8') #获取生意参谋流量数据数据 traffic_res

source(paste(Rfile,'sycm_jzproduct.r',sep=''),encoding = 'utf8') #获取生意参谋竞争商品数据数据 jzres

source(paste(Rfile,'sycm_industry_brand.r',sep=''),encoding = 'utf8') #获取生意参谋品牌排行数据 beauty cosmetics

#获取赤兔店铺自定义数据 chitu_basic
b$navigate('https://newkf.topchitu.com/ww/wwitemchat.shtml') #打开赤兔网站后需要点击两次按钮验证
b$findElement('css selector', 'body > div.container > div.background-image > div > div.logo-login > div.chitu-btn > div')$clickElement()
b$findElement('css selector', '#sub')$clickElement()

source(paste(Rfile,'chitu_keydata.r',sep=''),encoding = 'utf8')

#获取赤兔商品咨询数据 chitu_askpro
b$navigate('https://newkf.topchitu.com/ww/wwitemchat.shtml')
b$findElement('css selector', 'body > div.box.clear-fix > div > div > div.search.clear-fix > form > div:nth-child(3) > div > div.drop.clear-fix > div.drop-btn')$clickElement()
Sys.sleep(1)
b$findElement('css selector', 'body > div.box.clear-fix > div > div > div.search.clear-fix > form > div:nth-child(3) > div > div.drop.clear-fix > ul > li:nth-child(3) > a')$clickElement()  #商品组选择所有商品

source(paste(Rfile,'chitu_askpro.r',sep=''),encoding = 'utf8')

################  爬取直通车数据 #####################


# conn=odbcConnectAccess('\\\\192.168.1.11\\data\\\\data_zy.mdb')
#逻辑：先抓取3天转化，再合并1天转化
b$navigate('https://subway.simba.taobao.com/#!/report/bpreport/index')
Sys.sleep(3)
conn=odbcConnectAccess2007(zydb_dir)
st <- max(as.Date(sqlQuery(conn,'select 统计日期 from 推广_直通车')$统计日期))+1
ztc <- data.frame()
days <- seq.Date(st-3, Sys.Date()-3, by='day')
for (day in as.character(days)){
  b$navigate(paste('https://subway.simba.taobao.com/?#!/report/bpreport/index?tabId=2&page=1&rows=200&filterId=&subFilterId=&sortField=&sortBy=&tableViewId=&labels=&search=&group=&groupSelected=&campType=&start=',day,'&end=',day,'&chartCompareSelected=&chartCompareDate=&tcId=3',sep=''))
  Sys.sleep(5)
  b$findElement(using='tag name', 'body')$sendKeysToElement(list(key='end'))
  table <- b$getPageSource()[[1]] %>% htmlParse(encoding = "UTF-8") %>%readHTMLTable(header = TRUE, which = 10)
  data <- table[3:(nrow(table)-1),1:13]

  for(i in 1:13){
    data[,i]=iconv(data[,i],'utf8','gbk')
    data[,i]=gsub('￥','',data[,i])
    data[,i]=gsub(',','',data[,i])
    data[,i]=gsub('-','0',data[,i])
  }
  names(data) <- c('状态','商品名称','推广单元类型','计划名称','默认出价','展现量','点击量','点击率','花费','平均点击花费','点击转化率','投入产出比','总成交金额')
  data$点击率 <- as.numeric(gsub("%","",data$点击率))/100
  data$点击转化率 <- as.numeric(gsub("%","",data$点击转化率))/100
  for(i in 6:13){
    data[,i] <- as.numeric(data[,i])
  }
  #抓取直通车计划对应商品链接
  url=unlist(lapply(b$findElements(using='css selector', value='#magix_vf_main > div > vframe:nth-child(9) > div > table > tbody > tr > td > div:nth-child(2) > div > vframe:nth-child(3) > div > div table > tbody > tr > td:nth-child(2) > p > a:nth-child(2)'), function(item){item$getElementAttribute("href")}))
  data <- data.frame(统计日期=as.character(day),商品链接=url,data)
  ztc <- rbind(ztc,data)
  print(paste('直通车数据抓取完毕',day,sep=''))
}
##抓取近两天直通车一天转化数据
days <- seq.Date(Sys.Date()-2, Sys.Date()-1, by='day')
for (day in as.character(days)){
  b$navigate(paste('https://subway.simba.taobao.com/?#!/report/bpreport/index?tabId=2&page=1&rows=200&filterId=&subFilterId=&sortField=&sortBy=&tableViewId=&labels=&search=&group=&groupSelected=&campType=&start=',day,'&end=',day,'&chartCompareSelected=&chartCompareDate=&tcId=1',sep=''))
  Sys.sleep(5)
  b$findElement(using='tag name', 'body')$sendKeysToElement(list(key='end'))
  page <- unlist(b$getPageSource())
  table <- b$getPageSource()[[1]] %>% htmlParse(encoding = "UTF-8") %>%readHTMLTable(header = TRUE, which = 10)
  data <- table[3:(nrow(table)-1),1:13]
  for(i in 1:13){
    data[,i]=iconv(data[,i],'utf8','gbk')
    data[,i]=gsub('￥','',data[,i])
    data[,i]=gsub(',','',data[,i])
    data[,i]=gsub('-','0',data[,i])
  }
  names(data) <- c('状态','商品名称','推广单元类型','计划名称','默认出价','展现量','点击量','点击率','花费','平均点击花费','点击转化率','投入产出比','总成交金额')
  data$点击率 <- as.numeric(gsub("%","",data$点击率))/100
  data$点击转化率 <- as.numeric(gsub("%","",data$点击转化率))/100
  for(i in 6:13){
    data[,i] <- as.numeric(data[,i])
  }
  #抓取直通车计划对应商品链接
  url=unlist(lapply(b$findElements(using='css selector', value='#magix_vf_main > div > vframe:nth-child(9) > div > table > tbody > tr > td > div:nth-child(2) > div > vframe:nth-child(3) > div > div table > tbody > tr > td:nth-child(2) > p > a:nth-child(2)'), function(item){item$getElementAttribute("href")}))
  data <- data.frame(统计日期=as.character(day),商品链接=url,data)
  ztc <- rbind(ztc,data)
  print(paste('直通车数据抓取完毕',day,sep=''))
}
data <- sqlFetch(conn,'推广_直通车')
ztc <- rbind(data[as.Date(data$统计日期)+1<(st-3),],ztc)
ztc <- ztc[!duplicated(ztc),] #避免重复项

for(i in 1:7){
  ztc[,i] <- as.character(ztc[,i])
}
for(i in 8:15){
  ztc[,i] <- as.numeric(ztc[,i])
}

if (nrow(ztc)>nrow(data)){
  sqlQuery(conn,'delete * from 推广_直通车')
  repeat{if(nrow(sqlFetch(conn,'推广_直通车'))==0){break()}}
  sqlSave(conn,ztc,tablename = '推广_直通车',rownames =FALSE,append = TRUE)
}else{print('数据有误')}
odbcCloseAll()
################  爬取钻展数据 #####################
file.remove(paste('C:\\Users\\hanhoo\\Downloads\\',list.files('C:\\Users\\hanhoo\\Downloads\\'),sep=''))
b$navigate('https://zuanshi.taobao.com/indexbp.jsp#!/report2/download')
Sys.sleep(5)
b$findElement('css selector', '#magix_vf_main > div.report2 > div > div:nth-child(2) > div.fl.w400 > label:nth-child(2)')$clickElement()
b$findElement('css selector', '#magix_vf_main > div.report2 > div > div.report2-download-btn > a:nth-child(1)')$clickElement()
Sys.sleep(5)
filename <- list.files('C:\\Users\\hanhoo\\Downloads\\')[grep("计划日报表",list.files('C:\\Users\\hanhoo\\Downloads\\'))]
repeat{if(file.exists(filename)){break()}}
data <- read.xlsx(filename,1,encoding = 'utf8')
names(data) <- c('计划基本信息','统计日期','展现','点击','消耗','点击率','点击单价','千次展现成本','访客','深度进店量',	'访问时长','访问页面数','收藏宝贝量','收藏店铺量','添加购物车量','拍下订单量','拍下订单金额','成交订单量','成交订单金额','点击转化率','投资回报率')
data$计划基本信息 <- iconv(data$计划基本信息,'utf8','gbk')
for (i in 2:21){
  data[,i] <- as.character(data[,i])
}
data[is.na(data)] = 0
for (i in 3:21){
  data[,i] <- as.numeric(data[,i])
}
data$点击率=data$点击率/100
data$点击转化率=data$点击转化率/100
# 获取钻展计划对应的推广链接
match_data <- read.xlsx('\\\\192.168.1.11\\data\\辅助文件\\钻展计划对应链接.xlsx',1)
names(match_data)=c('计划基本信息','商品链接')
match_data$计划基本信息 <- iconv(match_data$计划基本信息,'utf8','gbk')
data <- merge(data,match_data,by='计划基本信息',all.x=TRUE)
data <- data[,c('统计日期','计划基本信息','商品链接','展现','点击','消耗','点击率','点击单价','千次展现成本','访客','深度进店量',	'访问时长','访问页面数','收藏宝贝量','收藏店铺量','添加购物车量','拍下订单量','拍下订单金额','成交订单量','成交订单金额','点击转化率','投资回报率')]

data[grepl('达人',data$计划基本信息),3]='http://detail.tmall.com/item.htm?id=37407455923'
data[grepl('茶蕊',data$计划基本信息),3]='http://detail.tmall.com/item.htm?id=45174064681'
data[grepl('气垫',data$计划基本信息),3]='http://detail.tmall.com/item.htm?id=536815914488' #18-15
data <- data[data$统计日期>(Sys.Date()-15), ]
data <- data[order(data$统计日期),]

## 将新抓取最近15天数据合并至数据表
conn=odbcConnectAccess2007(zydb_dir)
ydata <- sqlFetch(conn,'推广_钻展')
ydata <-ydata[ydata$统计日期<=(Sys.Date()-15), ]
ydata <- ydata[order(ydata$统计日期),]
zz <- rbind(ydata,data)
zz <- zz[!duplicated(zz),] #避免重复项

if (nrow(zz)>nrow(data)){
  sqlQuery(conn,'delete * from 推广_钻展')
  repeat{if(nrow(sqlFetch(conn,'推广_钻展'))==0){break()}}
  sqlSave(conn,zz,tablename = '推广_钻展',rownames =FALSE,append = TRUE)
  print(paste('钻展抓取到',max(zz$统计日期),sep=''))
}else{print('数据有误')}
odbcCloseAll()

#==========================================淘宝客=======================================================
b$navigate('http://ad.alimama.com/myunion.htm?spm=a21e2.8146997.458322.3.u1Dgse')
##密码  #@Hanhoo66235885
pagesource <- unlist(b$findElement(using='css selector', '#tb-beacon-aplus')$getElementAttribute("exparams"))
tkToken <- substring(pagesource , regexpr("yunid=&", pagesource)+7, regexpr("yunid=&", pagesource)+17)

b$navigate(paste('http://ad.alimama.com/cps/shopkeeper/overview.json?startTime=',Sys.Date()-90,'&endTime=',Sys.Date()-1,'&_tb_token_=',tkToken,sep=''))
pagesource <- unlist(b$findElement(using='css selector', 'body')$getElementText())
data <- jsonlite::fromJSON(pagesource)$data$listData
taoke=data[,c("thedate","click","commisionAmt","cmAlipayAmt","settleAmt","roi")]
names(taoke)=c('统计日期','点击量','佣金','引入付款金额','结算金额','ROI')

conn=odbcConnectAccess2007(zydb_dir)
tk=sqlFetch(conn,'推广_淘宝客')
taoke=rbind(subset(tk,as.Date(tk$统计日期)+1<(Sys.Date()-90)),taoke)
if (nrow(taoke)>nrow(tk)){
  sqlQuery(conn,'delete * from 推广_淘宝客')
  repeat{if(nrow(sqlFetch(conn,'推广_淘宝客'))==0){break()}}
  sqlSave(conn,taoke,tablename = '推广_淘宝客',rownames =FALSE,append = TRUE)
  print(paste('淘客抓取到',max(taoke$统计日期),sep=''))
}else{print('数据有误')}
odbcCloseAll()
rm(tk)
rm(match_data)
rm(ydata)









