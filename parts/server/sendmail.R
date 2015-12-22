













from <- sprintf("whatever@mapx.io")
to <- "nikos.alexandris@unepgrid.ch"
subject <- "Yoooo nikos ! spam festival ahead ! "
body <- list("What's up, dude. Here is iris dataset in mime part", mime_part(iris))
sendmail(from, to, subject, body,
  control=list(smtpServer="smtp.unige.ch"))




