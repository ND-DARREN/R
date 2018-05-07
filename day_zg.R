#########################################唯品会############################################################
zgdb_dir <- '//192.168.1.11/data/直供.accdb' #zydb_dir直营数据库地址
Rfile <- '\\\\192.168.1.11\\data\\spider_day\\'

# b$open(silent=T) 
b$navigate('http://vis.vip.com/index.php')
b$findElement(using='css selector', value='#userName')$sendKeysToElement(list("xiewei@hanhoo.com"))
b$findElement(using='css selector', value='#passWord')$sendKeysToElement(list("HANhoo2017@"))

source(paste(Rfile,'wp_dq&product.r',sep=''),encoding = 'utf8') #获取唯品会档期销售明细&档期商品明细 dqdata dq_pro

source(paste(Rfile,'wp_dq_analysis.r',sep=''),encoding = 'utf8') #获取唯品档期分析数据 salesdata wp_pro

#获取唯品库存
b$navigate('http://www.wph56.com/login')
b$findElement(using='css selector', value='#j_password')$sendKeysToElement(list(iconv("HANhoo2017!",from='gbk',to='utf8')))
b$findElement(using='css selector', value='#j_username')$sendKeysToElement(list(iconv("18620105761",from='gbk',to='utf8')))
#b$findElement(using='css selector', value='#doLogin')$clickElement()

source(paste(Rfile,'wp_stock.r',sep=''),encoding = 'utf8')


#########################################京东############################################################
b$navigate('https://passport.jd.com/new/login.aspx?ReturnUrl=https://vdc.jd.com')
repeat{
  if(b$findElement(using='css selector',value='#content > div.login-wrap > div.w > div > div.qrcode-login > div > div.qrcode-panel > ul > li:nth-child(2)')$getElementText()[[1]]=='扫描二维码'){b$findElement('css selector', '#content > div.login-wrap > div.w > div > div.login-tab.login-tab-r > a')$clickElement()} 
  if(b$findElement(using='css selector',value='#formlogin > div.item.item-fore4 > div > span.forget-pw-safe > a')$getElementText()[[1]]=='忘记密码'){break()}
}
b$findElement(using='css selector', value='#loginname')$sendKeysToElement(list(iconv("韩后2014",'gbk','utf8')))
b$findElement(using='css selector', value='#nloginpwd')$sendKeysToElement(list("Han&J1720#D"))
b$findElement('css selector', '#loginsubmit')$clickElement()
#抓取京东商品销售及库存数据
source(paste(Rfile,'jd.r',sep=''),encoding = 'utf8')

## 抓取商品流量数据,手动下载报表
b$navigate('https://tvdc.jd.com/index/indexPage#reports_reportCommodityTraffic')
b$navigate('https://tvdc.jd.com/index/indexPage#reports_reportCommodityTraffic')
file.remove(paste('C:\\Users\\hanhoo\\Downloads\\',list.files('C:\\Users\\hanhoo\\Downloads\\'),sep=''))
conn=odbcConnectAccess2007(zgdb_dir)
parts <- c('PC','APP','微信','手Q','M站')

for (i in 1:5){
  ## 确定需下载报表日期
  days <- sqlQuery(conn,paste("select distinct 日期 from 京东_流量 where 流量来源=",paste("'",parts[i],"'",sep=''),sep=''))
  days <- as.Date(as.character(days$日期))
  daylist <- seq.Date(as.Date('2018-02-01'),Sys.Date()-2,by='day')
  print(parts[i])
  print(daylist[!daylist %in% days])
}

downlaod <- parts[5]
## 读取下载数据
list <- list.files('C:\\Users\\hanhoo\\Downloads\\')
res <- data.frame()
for(i in 1:length(list)){
  data <- read.xlsx(list[i],1)
  res <- rbind(res,data)
  print(i)
}
res$流量来源 <- downlaod
names(res) <- c('日期','商品编码','商品名称','流量渠道','商品流量','商品访客','商品访次','商品消费者','商品订单行','商品转化率','流量来源')
res$商品名称 <- iconv(res$商品名称,'utf8','gbk')
res$流量渠道 <- iconv(res$流量渠道,'utf8','gbk')
res <- res[!duplicated(res),]
res <- res[,c('日期','流量来源','商品编码','商品名称','流量渠道','商品流量','商品访客','商品访次','商品消费者','商品订单行','商品转化率')]
data <- res[(!duplicated(res$日期)),1:2]
data$日期 <- sort(as.Date(as.character(data$日期)))

if(all(daylist[!daylist %in% days]==data$日期)){
  sqlSave(conn,res,tablename = '京东_流量',rownames =FALSE,append = TRUE)
  file.remove(paste('C:\\Users\\hanhoo\\Downloads\\',list.files('C:\\Users\\hanhoo\\Downloads\\'),sep=''))
}else{print('检查下载日期')}

odbcCloseAll()





