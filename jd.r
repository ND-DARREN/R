conn=odbcConnectAccess2007(zgdb_dir)
#---------获取价格表------------
b$navigate('https://vcp.jd.com/sub_item/price/findPriceList?vendorCode=gzhanhou&loginCode=韩后2014&categoryId=-1&length=1000&page=1&sidx=wareId&sord=desc')
pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
jdprice <- jsonlite::fromJSON(pagesource)$jsonList
jdprice <- jdprice[,c('wareId','name','price')]
names(jdprice)=c('商品编号','商品名称','采购价')
jdprice=unique(jdprice)
#----------获取商品销售数据---------
b$navigate('https://tvdc.jd.com/reportStockNum/queryDailyStockNumData?wareName=&vendorCode=&brandId=-1&threeCategoryId=-1&wareStatus=-1&sku=&dateType=1&pageNo=1&pageSize=300&module2Id=3000091')
pagesource <- unlist(b$findElement(using='css selector', 'body')$getElementText())
jdpro <- jsonlite::fromJSON(pagesource)$result
jdpro <- data.frame(商品编号=jdpro$itemSkuId,商品名称=jdpro$itemSkuName,品牌id=jdpro$itemSkuBrandId,品牌名称=jdpro$itemSkuBrandName,类目id=jdpro$skuCategory,全国总销量=jdpro$cid_0_saleCount,全国总库存=jdpro$cid_0_stockCount)
jdpro =merge(jdpro,jdprice[,-2],by='商品编号',all.x = T)
jdpro=data.frame(日期=as.character(Sys.Date()-1),jdpro,全国总销售额=as.numeric(as.character(jdpro$采购价))*as.numeric(as.character(jdpro$全国总销量)))
jdpro <- subset(jdpro,select = -c(品牌id,类目id))
if(nrow(jdpro)>100){sqlSave(conn,jdpro,tablename = '京东_商品销售',rownames =FALSE,append = TRUE)}else{'数据有误'}
#---存入库存数据-----
my_jd_stock=jdpro[,c( "日期","商品编号","商品名称","全国总库存")]
if (nrow(sqlFetch(conn,'京东_库存'))!=0){sqlQuery(conn,'delete * from 京东_库存')}
repeat{if(nrow(sqlFetch(conn,'京东_库存'))==0){break()}} #等待数据库清空
if (nrow(sqlFetch(conn,'京东_库存'))==0){sqlSave(conn,my_jd_stock,tablename = '京东_库存',rownames =FALSE,append = TRUE)}else{print('数据库未清空')}
print('京东数据抓取完毕')
odbcCloseAll()