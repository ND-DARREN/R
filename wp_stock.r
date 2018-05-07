#VIP_BJ华北仓,VIP_HZ 华中仓,VIP_SH 华东仓,VIP_NH 华南仓,VIP_CD西南仓
conn=odbcConnectAccess2007(zgdb_dir)
st=as.Date(max(sqlQuery(conn,'select 库存日期 from 唯品_进销存')$库存日期))+1
days=seq.Date(st+1,Sys.Date()-1,by='day')
wp_inventory=data.frame()
for (day in as.character(days)){
  warehouse=c('VIP_BJ','VIP_HZ','VIP_SH','VIP_NH','VIP_CD')
  for (i in 1:length(warehouse)){
    b$navigate(paste('http://www.wph56.com/inventory-report/purchaseSalesInventory/query?distributionModel=3PL&queryType=queryTypeItem&warehouseCode=',warehouse[i],'&poNo=&brandCode=&brandName=&itemCode=&dateFrom=',day,'&dateTo=',day,'&payCategory=&page=1&rows=600',sep=''))
    pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
    data<- jsonlite::fromJSON(pagesource)$rows
    wp_inventory=rbind(wp_inventory,data)
  }
  print(day)
}

wp_inventory=wp_inventory[,c('inventoryDate','warehouseCode','itemCode','itemName','beginningInventoryQuantity','inventoryOutQuantity','endingInventoryQuantity','inventoryInQuantity')]
wp_inventory$warehouseCode=gsub('VIP_BJ','华北仓',wp_inventory$warehouseCode)
wp_inventory$warehouseCode=gsub('VIP_HZ','华中仓',wp_inventory$warehouseCode)
wp_inventory$warehouseCode=gsub('VIP_SH','华东仓',wp_inventory$warehouseCode)
wp_inventory$warehouseCode=gsub('VIP_NH','华南仓',wp_inventory$warehouseCode)
wp_inventory$warehouseCode=gsub('VIP_CD','西南仓',wp_inventory$warehouseCode)
names(wp_inventory)=c('库存日期','仓库','商品编码','商品名称','期初库存','出库数量','期末库存','入库数量')

if (nrow(wp_inventory)>0&ncol(wp_inventory)==8){
  sqlSave(conn,wp_inventory,tablename = '唯品_进销存',rownames =FALSE,append = TRUE)
}else{"数据有误"}


#---存入库存数据-----
wp_stock=subset(wp_inventory,wp_inventory$库存日期==max(unique(wp_inventory$库存日期)))
wp_stock=wp_stock[,c('库存日期','仓库','商品编码','商品名称','期末库存')]
if (nrow(sqlFetch(conn,'唯品_库存'))!=0&nrow(wp_stock)>0){sqlQuery(conn,'delete * from 唯品_库存')}
repeat{if(nrow(sqlFetch(conn,'唯品_库存'))==0){break()}} #等待数据库清空
sqlSave(conn,wp_stock,tablename = '唯品_库存',rownames =FALSE,append = TRUE)

odbcCloseAll()
