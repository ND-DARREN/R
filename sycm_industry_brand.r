#抓取品牌排行函数
getBrand=function(cateId,day,seller,Token){
  Sys.sleep(runif(1,3,10))
  b$navigate(paste('https://sycm.taobao.com/mq/brand/rank.json?cateId=',cateId,'&dateRange=',day,'%7C',day,'&dateType=day&device=0&orderField=tradeIndex&orderType=desc&page=1&pageSize=100&rankType=0&search=&seller=',seller,'&sycmToken=',Token,'&totalPage=1&_=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),sep='')) #热销品牌榜
  pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
  branddata <- jsonlite::fromJSON(pagesource)$content$data$data
  branddata <- branddata[,c("brandId","brandName","tradeIndex","payOrderAmt","payByrRate","payItemCnt","pvIndex")]
  branddata<- branddata[order(-branddata$payOrderAmt),]
  branddata=data.frame(rankNo=c(1:500),branddata)
  branddata
}

#####抓取数据#####
conn=odbcConnectAccess2007(zydb_dir)
st=as.Date(max(unique(sqlQuery(conn,"select distinct(date) from 参谋_品牌排行 where catid=1801"))$date))+1 
days <- seq.Date(st+1, Sys.Date()-1, by='day')
if(length(days)>3){days=days[1:3]} #一次最多抓取三天数据，避免被封
beauty=data.frame()
for (day in as.character(days)){
  all=getBrand(1801,day,-1,Token)
  all=data.frame(date=day,pt='全网',catid='1801',cat='美容护肤/美体/精油',all)
  tm=getBrand(1801,day,1,Token)
  tm=data.frame(date=day,pt='天猫',catid='1801',cat='美容护肤/美体/精油',tm)
  tb=getBrand(1801,day,0,Token)
  tb=data.frame(date=day,pt='淘宝',catid='1801',cat='美容护肤/美体/精油',tb)
  brand=rbind(all,tm,tb)
  beauty <- rbind(beauty,brand)
}
beauty$date=as.factor(beauty$date)
beauty$cusNum=round(beauty$payByrRate*beauty$pvIndex,0)

if(sum(duplicated(beauty))==0){
  sqlSave(conn,beauty,tablename = '参谋_品牌排行',rownames =FALSE,append = TRUE)
  print(paste('已抓取美容护肤1801品牌排行数据',min(as.Date(beauty$date)),'至',max(as.Date(beauty$date)),sep=''))
  }else{print('数据有误')}

#彩妆
st=as.Date(max(unique(sqlQuery(conn,"select distinct(date) from 参谋_品牌排行 where catid=50010788"))$date))+1 
days <- seq.Date(st+1, Sys.Date()-1, by='day')
if(length(days)>3){days=days[1:3]} #一次最多抓取三天数据，避免被封
cosmetics=data.frame()
for (day in as.character(days)){
  all=getBrand(50010788,day,-1,Token)
  all=data.frame(date=day,pt='全网',catid='50010788',cat='彩妆/香水/美妆工具',all)
  tm=getBrand(50010788,day,1,Token)
  tm=data.frame(date=day,pt='天猫',catid='50010788',cat='彩妆/香水/美妆工具',tm)
  tb=getBrand(50010788,day,0,Token)
  tb=data.frame(date=day,pt='淘宝',catid='50010788',cat='彩妆/香水/美妆工具',tb)
  brand=rbind(all,tm,tb)
  cosmetics <- rbind(cosmetics,brand)
}
cosmetics$date=as.factor(cosmetics$date)
cosmetics$cusNum=round(cosmetics$payByrRate*cosmetics$pvIndex,0)

if(sum(duplicated(cosmetics))==0){
  sqlSave(conn,cosmetics,tablename = '参谋_品牌排行',rownames =FALSE,append = TRUE)
  print(paste('已抓取彩妆50010788品牌排行数据',min(as.Date(cosmetics$date)),'至',max(as.Date(cosmetics$date)),sep=''))
  }else{print('数据有误')}
odbcCloseAll()
remove(all)
remove(tm)
remove(tb)
remove(brand)



