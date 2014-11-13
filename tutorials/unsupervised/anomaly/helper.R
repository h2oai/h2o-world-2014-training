plotDigit <- function(mydata, rec_error) {
  len<-nrow(mydata)
  N<-ceiling(sqrt(len))
  par(mfrow=c(N,N),pty='s',mar=c(1,1,1,1),xaxt='n',yaxt='n')
  for (i in 1:nrow(mydata)) {
    colors<-c('white','black')
    cus_col<-colorRampPalette(colors=colors)
    z<-array(mydata[i,],dim=c(28,28))
    z<-z[,28:1]
    image(1:28,1:28,z,main=paste0("rec_error: ", round(rec_error[i],4)),col=cus_col(256))
  }
}

plotDigits <- function(data, rec_error, rows) {
  row_idx <- order(rec_error[,1],decreasing=F)[rows]
  my_rec_error <- rec_error[row_idx,]
  my_data <- as.matrix(as.data.frame(data[row_idx,]))
  plotDigit(my_data, my_rec_error)
}
