## 抓取赤兔自定义店铺基础销售数据
conn=odbcConnectAccess2007(zydb_dir)

b$navigate(paste('https://newkf.topchitu.com/customkpi/excel.shtml?t=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),'&reportId=2079&monthFrom=2017-02&monthTo=2017-03&from=',Sys.Date()-15,'&to=',Sys.Date()-1,'&wwgroupId=-1&employeeGroupId=-1&datepick_type=&wangwangNick=&employeeName=&advancedType=ww',sep=''))
repeat{if(file.exists(paste('自定义报表-chitu_',Sys.Date()-15,'至',Sys.Date()-1,'.xls',sep=''))){break()}}
chitu_basic=read.xlsx(paste('自定义报表-chitu_',Sys.Date()-15,'至',Sys.Date()-1,'.xls',sep=''),1, encoding="UTF-8")
chitu_basic=chitu_basic[1:(nrow(chitu_basic)-2),]
for (i in 2:20){
  chitu_basic[,i]=as.numeric(as.character(chitu_basic[,i]))
}
ct=sqlFetch(conn,'赤兔_客服销售')
names(chitu_basic)=names(ct)
chitu_basic <- rbind(subset(ct,ct$日期<Sys.Date()-15),chitu_basic) #合并数据
chitu_basic <- chitu_basic[order(as.Date(chitu_basic$日期)),] #排序
chitu_basic <- chitu_basic[!duplicated(chitu_basic$日期),]

if (nrow(chitu_basic)>nrow(ct)){
  sqlQuery(conn,'delete * from 赤兔_客服销售')
  repeat{if (nrow(sqlFetch(conn,'赤兔_客服销售'))==0){break()}}
  sqlSave(conn,chitu_basic,tablename = '赤兔_客服销售',rownames =FALSE, append = T)
  print(paste('已抓取赤兔店铺自定义数据',min(as.Date(chitu_basic$日期))+1,'至',max(as.Date(chitu_basic$日期))+1,sep=''))
}else{print('数据有误')}

odbcCloseAll()
rm(ct)


