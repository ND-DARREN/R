conn=odbcConnectAccess2007(zydb_dir)
b$navigate('https://sycm.taobao.com/adm/v2/downloadById.do?spm=a21ag.10575379.0.0.688d1c781tdO5e&id=5738&reportType=1')
repeat{if(file.exists(paste('店铺整体-',Sys.Date(),'.xls',sep=''))){break()}}
data <- read.xlsx(paste('店铺整体-',Sys.Date(),'.xls',sep=''),1,encoding="UTF-8")
for (i in 1:105){
  data[,i] <- as.character(data[,i])
  data[,i] <-gsub(',','',data[,i])
}
names(data) <- data[5,]
data <- data[6:nrow(data),]
## 将百分比列转化成数字
index <- match(c('跳失率','无线端跳失率','PC端跳失率','下单转化率','PC端下单转化率','无线端下单转化率','支付转化率','PC端支付转化率','无线端支付转化率','下单-支付转化率','PC端下单-支付转化率','无线端下单-支付转化率'),names(data))
for(i in index){
  data[,i]=as.numeric(gsub("%","",data[,i]))/100
}
## 将非百分比列转化成数字
index1 <- setdiff(1:105,c(index,1))
for(i in index1){
  data[,i]=as.numeric(data[,i])
}

data <- data[,c("统计日期","浏览量","访客数","老访客数","新访客数","商品浏览量","商品访客数","平均停留时长","跳失率","下单买家数","支付买家数","支付转化率","支付老买家数","老买家支付金额","支付件数","支付金额","客单价","支付商品数","加购人数","加购件数","店铺收藏买家数","商品收藏买家数","成功退货退款金额","直通车消耗","钻石展位消耗","淘宝客佣金","评价数","有图评价数","正面评价数","负面评价数","老买家正面评价数","老买家负面评价数","揽收包裹数","发货包裹数","派送包裹数","签收成功包裹数","平均支付_签收时长(秒)", "描述相符评分","物流服务评分","服务态度评分")]
names(data)[37]='平均支付_签收时长秒'

st <- max(as.Date(sqlQuery(conn,'select 统计日期 from 参谋_店铺运营')$统计日期))+1
basic <- data[data$统计日期>st, ]
if(nrow(basic)>0){
  sqlSave(conn,basic,tablename = '参谋_店铺运营',rownames =FALSE,append = TRUE)
  print(paste(basic$统计日期,'店铺运营数据抓取完毕'))
  }else{print("无店铺数据")}
odbcCloseAll()




