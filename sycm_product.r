#########爬取生意参谋商品销售数据########
conn=odbcConnectAccess2007(zydb_dir)
st <- max(as.Date(sqlQuery(conn,'select distinct 日期 from 参谋_商品销售')$日期))+1 #POSIXct型转换as.date日期会变小一天
days <- seq.Date(st+1, Sys.Date()-1, by='day')

product_res=data.frame()
for (day in as.character(days)){
  Sys.sleep(runif(1,1,3))
  b$navigate(paste('https://sycm.taobao.com/bda/items/effect/getItemsEffectDetail.json?dateRange=',day,'%7C',day,'&dateType=day&device=0&orderDirection=false&orderField=itemUv&page=1&pageLimit=300&token=',Token,'&type=0&_=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),sep=''))
  pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
  product_all_itemEffectIndex<- jsonlite::fromJSON(pagesource)$data$data$itemEffectIndex
  product_all_itemModel<- jsonlite::fromJSON(pagesource)$data$data$itemModel
  product_all=merge(product_all_itemModel,product_all_itemEffectIndex,by="id")
  product_all$date=day
  product_all$pt='所有终端'
  product_all=product_all[,c('date','pt','id','title','itemDetailUrl','itemPv','itemUv','avgStayTime','avgBounceUvRate','orderRate','orderToPayRate','payRate','orderAmt','orderItemQty','orderBuyerCnt','payAmt','payItemQty','addCartItemCnt','uvAvgPayAmt','clickCnt','clickRate','expose','favBuyerCnt','payBuyerCntSe','payPct','sePayRate','uvSe','payBuyerCnt')]
  
  Sys.sleep(runif(1,1,3))
  b$navigate(paste('https://sycm.taobao.com/bda/items/effect/getItemsEffectDetail.json?dateRange=',day,'%7C',day,'&dateType=day&device=1&orderDirection=false&orderField=itemUv&page=1&pageLimit=300&token=',Token,'&type=0&_=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),sep=''))
  pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
  product_pc_itemEffectIndex<- jsonlite::fromJSON(pagesource)$data$data$itemEffectIndex
  product_pc_itemModel<- jsonlite::fromJSON(pagesource)$data$data$itemModel
  product_pc=merge(product_pc_itemModel,product_pc_itemEffectIndex,by="id")
  product_pc$date=day
  product_pc$pt='pc端'
  product_pc=product_pc[,c('date','pt','id','title','itemDetailUrl','itemPv','itemUv','avgStayTime','avgBounceUvRate','orderRate','orderToPayRate','payRate','orderAmt','orderItemQty','orderBuyerCnt','payAmt','payItemQty','addCartItemCnt','uvAvgPayAmt','clickCnt','clickRate','expose','favBuyerCnt','payBuyerCntSe','payPct','sePayRate','uvSe','payBuyerCnt')]
  
  Sys.sleep(runif(1,1,3))
  b$navigate(paste('https://sycm.taobao.com/bda/items/effect/getItemsEffectDetail.json?dateRange=',day,'%7C',day,'&dateType=day&device=2&orderDirection=false&orderField=itemUv&page=1&pageLimit=300&token=',Token,'&type=0&_=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),sep=''))
  pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
  product_wx_itemEffectIndex<- jsonlite::fromJSON(pagesource)$data$data$itemEffectIndex
  product_wx_itemModel<- jsonlite::fromJSON(pagesource)$data$data$itemModel
  product_wx=merge(product_wx_itemModel,product_wx_itemEffectIndex,by="id")
  product_wx$date=day
  product_wx$pt='无线端'
  product_wx=product_wx[,c('date','pt','id','title','itemDetailUrl','itemPv','itemUv','avgStayTime','avgBounceUvRate','orderRate','orderToPayRate','payRate','orderAmt','orderItemQty','orderBuyerCnt','payAmt','payItemQty','addCartItemCnt','uvAvgPayAmt','clickCnt','clickRate','expose','favBuyerCnt','payBuyerCntSe','payPct','sePayRate','uvSe','payBuyerCnt')]
  product_combine=rbind(product_all,product_pc,product_wx)
  product_res=rbind(product_res,product_combine)
}
names(product_res)=c("日期","所属终端","商品id","商品标题","商品链接","浏览量","访客数","平均停留时长","详情页跳出率","下单转化率","下单支付转化率","支付转化率","下单金额","下单商品件数","下单买家数","支付金额","支付商品件数","加购件数","访客平均价值","点击次数","点击率","曝光量","收藏人数","搜索引导支付买家数","客单价","搜索支付转化率","搜索引导访客数","支付买家数")
product_res$商品id=as.character(product_res$商品id)
product_res$商品链接 <- gsub('//detail.tmall.com','http://detail.tmall.com',product_res$商品链接)
if (min(as.Date(product_res$日期))==st+1&ncol(product_res)==28){
  sqlSave(conn,product_res,tablename = '参谋_商品销售',rownames =FALSE,append = TRUE)
  print(paste('已抓取商品数据',min(product_res$日期),'至',max(product_res$日期),sep=''))
}else{print("数据有误，请检查")}
odbcCloseAll()
rm(product_all)
rm(product_all_itemEffectIndex)
rm(product_all_itemModel)
rm(product_combine)
rm(product_pc)
rm(product_pc_itemEffectIndex)
rm(product_pc_itemModel)
rm(product_wx)
rm(product_wx_itemEffectIndex)
rm(product_wx_itemModel)







