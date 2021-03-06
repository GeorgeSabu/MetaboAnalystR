### Perform miscellaneous tasks
### Perform misc tasks
### Jeff Xia\email{jeff.xia@mcgill.ca}
### McGill University, Canada
###License: GNU GPL (>= 2)


#'Merge duplicated columns or rows by their mean
#'@description dim 1 => row,  dim 2 => column
#'@param data Input the data
#'@param dim Numeric, input the dimensions, default is set to 2
#'@export
#'
MergeDuplicates <- function(data, dim=2){
  
  if(is.null(dim(data))){ # a vector
    if(is.null(names(data))){
      print("Cannot detect duplicate data without names!!!");
      return();
    }
    nm.cls <- as.factor(names(data));
    uniq.len <- length(levels(nm.cls));
    if(uniq.len == length(data)){
      return(data);
    }
    new.data <- vector (mode="numeric",length=uniq.len);
    for(i in 1:uniq.len){
      dup.inx <- nm.cls == levels(nm.cls)[i];
      new.data[i] <- mean(data[dup.inx]);
    }
    names(new.data) <- levels(nm.cls);
    rem.len <- length(data) - length(new.data);
  }else{
    if(dim == 1){
      data <- t(data);
    }
    if(is.null(colnames(data))){
      print("Cannot detect duplicate data without var names!!!");
      return();
    }
    
    nm.cls <- as.factor(colnames(data));
    uniq.len <- length(levels(nm.cls));
    
    if(uniq.len == ncol(data)){
      if(dim == 1){
        data <- t(data);
      }
      return(data);
    }
    
    new.data <- matrix (nrow=nrow(data), ncol=uniq.len);
    for(i in 1:uniq.len){
      dup.inx <- which(nm.cls == levels(nm.cls)[i]);
      new.data[,i] <- apply(data[,dup.inx, drop=F], 1, mean);
    }
    rownames(new.data) <- rownames(data);
    colnames(new.data) <- levels(nm.cls);
    
    rem.len <- ncol(data) - ncol(new.data);
    if(dim == 1){
      new.data <- t(new.data);
    }
  }
  print(paste(rem.len, "duplicates are merged to their average"));
  new.data;
}

#'Given a data with duplicates, remove duplicates
#'@description Dups is the one with duplicates
#'@param data Input data to remove duplicates
#'@param lvlOpt Set options, default is mean
#'@param quiet Set to quiet, logical, default is T
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'@export
#'
RemoveDuplicates <- function(data, lvlOpt="mean", quiet=T){
  
  all.nms <- rownames(data);
  colnms <- colnames(data);
  dup.inx <- duplicated(all.nms);
  dim.orig  <- dim(data);
  data <- apply(data, 2, as.numeric); # force to be all numeric
  dim(data) <- dim.orig; # keep dimension (will lost when only one item) 
  rownames(data) <- all.nms;
  colnames(data) <- colnms;
  if(sum(dup.inx) > 0){
    uniq.nms <- all.nms[!dup.inx];
    uniq.data <- data[!dup.inx,,drop=F];
    
    dup.nms <- all.nms[dup.inx];
    uniq.dupnms <- unique(dup.nms);
    uniq.duplen <- length(uniq.dupnms);
    
    for(i in 1:uniq.duplen){
      nm <- uniq.dupnms[i];
      hit.inx.all <- which(all.nms == nm);
      hit.inx.uniq <- which(uniq.nms == nm);
      
      # average the whole sub matrix 
      if(lvlOpt == "mean"){
        uniq.data[hit.inx.uniq, ]<- apply(data[hit.inx.all,,drop=F], 2, mean, na.rm=T);
      }else if(lvlOpt == "median"){
        uniq.data[hit.inx.uniq, ]<- apply(data[hit.inx.all,,drop=F], 2, median, na.rm=T);
      }else if(lvlOpt == "max"){
        uniq.data[hit.inx.uniq, ]<- apply(data[hit.inx.all,,drop=F], 2, max, na.rm=T);
      }else{ # sum
        uniq.data[hit.inx.uniq, ]<- apply(data[hit.inx.all,,drop=F], 2, sum, na.rm=T);
      }
    }
    AddMsg(paste("A total of ", sum(dup.inx), " of duplicates were replaced by their ", lvlOpt, ".", sep=""));
    return(uniq.data);
  }else{
    AddMsg("All IDs are unique.");
    return(data);
  }
} 

#'Read data table
#'@description note, try to use the fread, however, it has issues with 
#'some windows 10 files "Line ending is \r\r\n. .... appears to add the extra \r in text mode on Windows"
#'in such as, use the slower read.table method
#'@param fileName Input filename
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'@export
#'
.readDataTable <- function(fileName){
  dat <- try(data.table::fread(fileName, header=TRUE, check.names=FALSE, data.table=FALSE));
  if(class(dat) == "try-error"){
    # try to use "tr" to remove double return characters
    trFileName <- paste("tr -d \'\\r\' <", fileName);
    dat <- try(data.table::fread(trFileName, header=TRUE, check.names=FALSE, data.table=FALSE));
    if(any(dim(dat) == 0) | class(dat) == "try-error"){
      print("Using slower file reader ...");
      formatStr <- substr(fileName, nchar(fileName)-2, nchar(fileName))
      if(formatStr == "txt"){
        dat <- try(read.table(fileName, header=TRUE, comment.char = "", check.names=F, as.is=T));
      }else{ # note, read.csv is more than read.table with sep=","
        dat <- try(read.csv(fileName, header=TRUE, comment.char = "", check.names=F, as.is=T));
      }  
    }
  }
  return(dat);
}

#'Transform 2 column text to data matrix
#'@description Transform two column input text to data matrix (single column data frame)
#'@param txtInput Input text
#'@param sep.type Indicate the seperator type for input text. Default set to "space"
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'@export
#'
getDataFromTextArea <- function(txtInput, sep.type="space"){
  
  lines <- unlist(strsplit(txtInput, "\r|\n|\r\n")[1]);
  if(substring(lines[1],1,1)=="#"){
    lines <- lines[-1];
  }
  
  # separated by tab 
  if(sep.type=="tab"){
    my.lists <- strsplit(lines, "\\t");
  }else{ # from any space
    my.lists <- strsplit(lines, "\\s+");
  }
  my.mat <- do.call(rbind, my.lists);
  
  if(dim(my.mat)[2] == 1){ # add 0
    my.mat <- cbind(my.mat, rep(0, nrow(my.mat)));
  }else if(dim(my.mat)[2] > 2){
    my.mat <- my.mat[,1:2];
    msg <- "More than two columns found in the list. Only first two columns will be used."
    AddErrMsg(msg);
  }
  rownames(my.mat) <- data.matrix(my.mat[,1]);
  my.mat <- my.mat[,-1, drop=F];
  return(my.mat);
}

#'Permutation
#'@description Perform permutation, options to change number of cores used
#'@param perm.num Numeric, input the number of permutations to perform
#'@param fun Dummy function
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'@usage Perform.permutation(perm.num, fun)
#'@export
#'
Perform.permutation <- function(perm.num, fun){
  print(paste("performing", perm.num, "permutations ..."));
  perm.res <- lapply(2:perm.num, fun);
  perm.res;
}

#'Unzip .zip files
#'@description Unzips uploaded .zip files, removes the uploaded file, checks for success
#'@param inPath Input the path of the zipped files
#'@param outPath Input the path to directory where the unzipped files will be deposited
#'@param rmFile Logical, input whether or not to remove files. Default set to T
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'@export
#'
UnzipUploadedFile<-function(inPath, outPath, rmFile=T){
  
  a<-try(system(paste("unzip",  "-o", inPath, "-d", outPath), intern=T));
  if(class(a) == "try-error" | !length(a)>0){
    AddErrMsg("Failed to unzip the uploaded files!");
    AddErrMsg("Possible reason: file name contains space or special characters.");
    AddErrMsg("Use only alphabets and numbers, make sure there is no space in your file name.");
    AddErrMsg("For WinZip 12.x, use \"Legacy compression (Zip 2.0 compatible)\"");
    return (0);
  }
  if(rmFile){
    RemoveFile(inPath);
  }
  return (1);
}

#'Calculate Fisher's Least Significant Difference (LSD)
#'@description Adapted from the 'agricolae' package
#'@param y Input Y
#'@param trt Input trt
#'@param alpha Numeric, default is 0.05
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)

LSD.test <- function(y, trt, alpha = 0.05){
  clase<-c("aov","lm")
  name.y <- paste(deparse(substitute(y)))
  name.t <- paste(deparse(substitute(trt)))
  if("aov"%in%class(y) | "lm"%in%class(y)){
    A<-y$model
    DFerror<-df.residual(y)
    MSerror<-deviance(y)/DFerror
    y<-A[,1]
    ipch<-pmatch(trt,names(A))
    name.t <-names(A)[ipch]
    trt<-A[,ipch]
    name.y <- names(A)[1]
  }
  junto <- subset(data.frame(y, trt), is.na(y) == FALSE)
  means <- tapply.stat(junto[, 1], junto[, 2], stat="mean") #change
  sds <- tapply.stat(junto[, 1], junto[, 2], stat="sd")     #change
  nn <- tapply.stat(junto[, 1], junto[, 2], stat="length")  #change
  std.err <- sds[, 2]/sqrt(nn[, 2])
  Tprob <- qt(1 - alpha/2, DFerror)
  LCL <- means[,2]-Tprob*std.err
  UCL <- means[,2]+Tprob*std.err
  means <- data.frame(means, std.err, replication = nn[, 2], LCL, UCL)
  names(means)[1:2] <- c(name.t, name.y)
  #row.names(means) <- means[, 1]
  ntr <- nrow(means)
  nk <- choose(ntr, 2)
  nr <- unique(nn[, 2])
  
  comb <- combn(ntr, 2)
  nn <- ncol(comb)
  dif <- rep(0, nn)
  LCL1<-dif
  UCL1<-dif
  sig<-NULL
  pvalue <- rep(0, nn)
  for (k in 1:nn) {
    i <- comb[1, k]
    j <- comb[2, k]
    if (means[i, 2] < means[j, 2]){
      comb[1, k]<-j
      comb[2, k]<-i
    }
    dif[k] <- abs(means[i, 2] - means[j, 2])
    sdtdif <- sqrt(MSerror * (1/means[i, 4] + 1/means[j,4]))
    pvalue[k] <- 2 * (1 - pt(dif[k]/sdtdif, DFerror));
    pvalue[k] <- round(pvalue[k],6);
    LCL1[k] <- dif[k] - Tprob*sdtdif
    UCL1[k] <- dif[k] + Tprob*sdtdif
    sig[k]<-" "
    if (pvalue[k] <= 0.001) sig[k]<-"***"
    else  if (pvalue[k] <= 0.01) sig[k]<-"**"
    else  if (pvalue[k] <= 0.05) sig[k]<-"*"
    else  if (pvalue[k] <= 0.1) sig[k]<-"."
  }
  tr.i <- means[comb[1, ],1]
  tr.j <- means[comb[2, ],1]
  output<-data.frame("Difference" = dif, pvalue = pvalue,sig,LCL=LCL1,UCL=UCL1)
  rownames(output)<-paste(tr.i,tr.j,sep=" - ");
  output;
}

#'Perform data cleaning
#'@description Cleans data and removes -Inf, Inf, NA, negative and 0s.
#'@param bdata Input data to clean
#'@param removeNA Logical, T to remove NAs, F to not. 
#'@param removeNeg Logical, T to remove negative numbers, F to not. 
#'@param removeConst Logical, T to remove samples/features with 0s, F to not. 
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'

CleanData <-function(bdata, removeNA=T, removeNeg=T, removeConst=T){
  
  if(sum(bdata==Inf, na.rm=TRUE)>0){
    inx <- bdata == Inf;
    bdata[inx] <- NA;
    bdata[inx] <- max(bdata, na.rm=T)*2
  }
  if(sum(bdata==-Inf, na.rm=TRUE)>0){
    inx <- bdata == -Inf;
    bdata[inx] <- NA;
    bdata[inx] <- min(bdata, na.rm=T)/2
  }
  if(removeNA){
    if(sum(is.na(bdata))>0){
      bdata[is.na(bdata)] <- min(bdata, na.rm=T)/2
    }
  }
  if(removeNeg){
    if(sum(as.numeric(bdata<=0)) > 0){
      inx <- bdata <= 0;
      bdata[inx] <- NA;
      bdata[inx] <- min(bdata, na.rm=T)/2
    }
  }
  if(removeConst){
    varCol <- apply(data.frame(bdata), 2, var, na.rm=T); # getting an error of dim(X) must have a positive length, fixed by data.frame
    constCol <- (varCol == 0 | is.na(varCol));
    constNum <- sum(constCol, na.rm=T);
    if(constNum > 0){
      bdata <- data.frame(bdata[,!constCol, drop=FALSE]); # got an error of incorrect number of dimensions, added drop=FALSE to avoid vector conversion
    }
  }
  bdata;
}

#'Replace infinite numbers
#'@description Replace -Inf, Inf to 99999 and -99999
#'@param bdata Input matrix to clean numbers
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'
CleanNumber <-function(bdata){
  if(sum(bdata==Inf)>0){
    inx <- bdata == Inf;
    bdata[inx] <- NA;
    bdata[inx] <- 999999;
  }
  if(sum(bdata==-Inf)>0){
    inx <- bdata == -Inf;
    bdata[inx] <- NA;
    bdata[inx] <- -999999;
  }
  bdata;
}

#'Remove spaces
#'@description Remove from, within, leading and trailing spaces
#'@param query Input the query to clear
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)

ClearStrings<-function(query){
  # kill multiple white space
  query <- gsub(" +"," ",query);
  # remove leading and trailing space
  query<- sub("^[[:space:]]*(.*?)[[:space:]]*$", "\\1", query, perl=TRUE);
  return(query);
}

# Remove HTML tag
PrepareLatex <- function(stringVec){
  stringVec <- gsub("<(.|\n)*?>","",stringVec);
  stringVec <- gsub("%", "\\\\%", stringVec);
  stringVec;
}

#'Determine value label for plotting
#'@description Concentration or intensity data type
#'@param data.type Input concentration or intensity data
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'@export
#'
GetAbundanceLabel<-function(data.type){
  if(data.type=="conc"){
    return("Concentration");
  }else {
    return("Intensity");
  }
}

#'Determine variable label for plotting
#'@description Determine data type, binned spectra, nmr peak, or ms peak
#'@param data.type Input the data type
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'@export
#'
GetVariableLabel<-function(data.type){
  if(data.type=="conc"){
    return("Compounds");
  }else if(data.type=="specbin"){
    return("Spectra Bins");
  }else if(data.type=="nmrpeak"){
    return("Peaks (ppm)");
  }else if(data.type=="mspeak"){
    return("Peaks (mass)");
  }else{
    return("Peaks(mz/rt)");
  }
}

#'Create Latex table
#'@description generate Latex table
#'@param mat Input matrix
#'@param method Input method to create table
#'@param data.type Input the data type
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'@export

GetSigTable<-function(mat, method, data.type){
  if(!isEmptyMatrix(mat)){ # test if empty
    cap<-"Important features identified by";
    if(nrow(mat)>50){
      smat<-as.matrix(mat[1:50,]); # only print top 50 if too many
      colnames(smat)<-colnames(mat); # make sure column names are also copied
      mat<-smat;
      cap<-"Top 50 features identified by";
    }
    # change the rowname to first column
    col1<-rownames(mat);
    cname<-colnames(mat);
    cname<-c(GetVariableLabel(data.type), cname);
    mat<-cbind(col1, mat);
    rownames(mat)<-NULL;
    colnames(mat)<-cname;
    print(xtable::xtable(mat, caption=paste(cap, method)), caption.placement="top", size="\\scriptsize");
  }else{
    print(paste("No significant features were found using the given threshold for", method));
  }
}

#'Sig table matrix is empty
#'@description Test if a sig table matrix is empty
#'@param mat Matrix to test if empty
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)

isEmptyMatrix <- function(mat){
  if(is.null(mat) | length(mat)==0){
    return(TRUE);
  }
  if(nrow(mat)==0 | ncol(mat)==0){
    return(TRUE);
  }
  if(is.na(mat[1,1])){
    return(TRUE);
  }
  return(FALSE);
}

#'Compute within group and between group sum of squares
#'(BSS/WSS) for each row of a matrix which may have NA
#'@description Columns have labels, x is a numeric vector,
#'cl is consecutive integers
#'@param x Numeric vector
#'@param cl Columns
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)

Get.bwss<-function(x, cl){
  K <- max(cl) - min(cl) + 1
  tvar <- var.na(x);
  tn <- sum(!is.na(x));
  wvar <- wn <- numeric(K);
  
  for(i in (1:K)) {
    if(sum(cl == (i + min(cl) - 1)) == 1){
      wvar[i] <- 0;
      wn[i] <- 1;
    }
    
    if(sum(cl == (i + min(cl) - 1)) > 1) {
      wvar[i] <- var.na(x[cl == (i + min(cl) - 1)]);
      wn[i] <- sum(!is.na(x[cl == (i + min(cl) - 1)]));
    }
  }
  
  WSS <- sum.na(wvar * (wn - 1));
  TSS <- tvar * (tn - 1)
  (TSS - WSS)/WSS;
}

sum.na <- function(x,...){
  res <- NA
  tmp <- !(is.na(x) | is.infinite(x))
  if(sum(tmp) > 0)
    res <- sum(x[tmp])
  res
}


var.na <- function(x){
  res <- NA
  tmp <- !(is.na(x) | is.infinite(x))
  if(sum(tmp) > 1){
    res <- var(x[tmp])
  }
  res
}

tapply.stat <-function (y, x, stat = "mean"){
  cx<-deparse(substitute(x))
  cy<-deparse(substitute(y))
  x<-data.frame(c1=1,x)
  y<-data.frame(v1=1,y)
  nx<-ncol(x)
  ny<-ncol(y)
  namex <- names(x)
  namey <- names(y)
  if (nx==2) namex <- c("c1",cx)
  if (ny==2) namey <- c("v1",cy)
  namexy <- c(namex,namey)
  for(i in 1:nx) {
    x[,i]<-as.character(x[,i])
  }
  z<-NULL
  for(i in 1:nx) {
    z<-paste(z,x[,i],sep="&")
  }
  w<-NULL
  for(i in 1:ny) {
    m <-tapply(y[,i],z,stat)
    m<-as.matrix(m)
    w<-cbind(w,m)
  }
  nw<-nrow(w)
  c<-rownames(w)
  v<-rep("",nw*nx)
  dim(v)<-c(nw,nx)
  for(i in 1:nw) {
    for(j in 1:nx) {
      v[i,j]<-strsplit(c[i],"&")[[1]][j+1]
    }
  }
  rownames(w)<-NULL
  junto<-data.frame(v[,-1],w)
  junto<-junto[,-nx]
  names(junto)<-namexy[c(-1,-(nx+1))]
  return(junto)
}

# List of objects
# Improved list of objects
# Jeff Xia\email{jeff.xia@mcgill.ca}
# McGill University, Canada
# License: GNU GPL (>= 2)

.ls.objects <- function (pos = 1, pattern, order.by,
                         decreasing=FALSE, head=FALSE, n=5) {
  napply <- function(names, fn) sapply(names, function(x)
    fn(get(x, pos = pos)))
  names <- ls(pos = pos, pattern = pattern)
  obj.class <- napply(names, function(x) as.character(class(x))[1])
  obj.mode <- napply(names, mode)
  obj.type <- ifelse(is.na(obj.class), obj.mode, obj.class)
  obj.prettysize <- napply(names, function(x) {
    capture.output(format(utils::object.size(x), units = "auto")) })
  obj.size <- napply(names, object.size)
  obj.dim <- t(napply(names, function(x)
    as.numeric(dim(x))[1:2]))
  vec <- is.na(obj.dim)[, 1] & (obj.type != "function")
  obj.dim[vec, 1] <- napply(names, length)[vec]
  out <- data.frame(obj.type, obj.size, obj.prettysize, obj.dim)
  names(out) <- c("Type", "Size", "PrettySize", "Rows", "Columns")
  if (!missing(order.by))
    out <- out[order(out[[order.by]], decreasing=decreasing), ]
  if (head)
    out <- head(out, n)
  out
}

#'Extend axis
#'@description Extends the axis range to both ends
#'vec is the values for that axis
#'unit is the width to extend, 10 will increase by 1/10 of the range
#'@param vec Input the vector
#'@param unit Numeric
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
GetExtendRange<-function(vec, unit=10){
  var.max <- max(vec, na.rm=T);
  var.min <- min(vec, na.rm=T);
  exts <- (var.max - var.min)/unit;
  c(var.min-exts, var.max+exts);
}

getVennCounts <- function(x, include="both") {
  x <- as.matrix(x)
  include <- match.arg(include,c("both","up","down"))
  x <- sign(switch(include,
                   both = abs(x),
                   up = x > 0,
                   down = x < 0
  ))
  nprobes <- nrow(x)
  ncontrasts <- ncol(x)
  names <- colnames(x)
  if(is.null(names)) names <- paste("Group",1:ncontrasts)
  noutcomes <- 2^ncontrasts
  outcomes <- matrix(0,noutcomes,ncontrasts)
  colnames(outcomes) <- names
  for (j in 1:ncontrasts)
    outcomes[,j] <- rep(0:1,times=2^(j-1),each=2^(ncontrasts-j))
  xlist <- list()
  for (i in 1:ncontrasts) xlist[[i]] <- factor(x[,ncontrasts-i+1],levels=c(0,1))
  counts <- as.vector(table(xlist))
  structure(cbind(outcomes,Counts=counts),class="VennCounts")
}

# Perform utilities for MetPa
# borrowed from Hmisc
# Jeff Xia\email{jeff.xia@mcgill.ca}
# McGill University, Canada
# License: GNU GPL (>= 2)
all.numeric <- function (x, what = c("test", "vector"), extras = c(".", "NA")){
  what <- match.arg(what)
  old <- options(warn = -1)
  on.exit(options(old));
  x <- sub("[[:space:]]+$", "", x);
  x <- sub("^[[:space:]]+", "", x);
  inx <- x %in% c("", extras);
  xs <- x[!inx];
  isnum <- !any(is.na(as.numeric(xs)))
  if (what == "test") 
    isnum
  else if (isnum) 
    as.numeric(x)
  else x
}

ClearNumerics <-function(dat.mat){
  dat.mat[is.na(dat.mat)] <- -777;
  dat.mat[dat.mat == Inf] <- -999;
  dat.mat[dat.mat == -Inf] <- -111;
  dat.mat;
}

#'Calculate Pairwise Differences
#'@description Mat are log normalized, diff will be ratio. Used in higher functions. 
#'@param mat Input matrix of data to calculate pair-wise differences.
#'@author Jeff Xia \email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'
CalculatePairwiseDiff <- function(mat){
  f <- function(i, mat) {
    z <- mat[, i-1] - mat[, i:ncol(mat), drop = FALSE]
    colnames(z) <- paste(colnames(mat)[i-1], colnames(z), sep = "/")
    z
  }
  res <- do.call("cbind", sapply(2:ncol(mat), f, mat));
  round(res,5);
}

##############################################
##############################################
########## Utilities for web-server ##########
##############################################
##############################################

# col.vec should already been created
UpdateGraphSettings <- function(mSetObj=NA, colVec, shapeVec){
  mSetObj <- .get.mSet(mSetObj);
  grpnms <- GetGroupNames(mSetObj);
  names(colVec) <- grpnms;
  names(shapeVec) <- grpnms;
  colVec <<- colVec;
  shapeVec <<- shapeVec;
}

GetShapeSchema <- function(mSetObj=NA, show.name, grey.scale){
  mSetObj <- .get.mSet(mSetObj);
  if(exists("shapeVec") && all(shapeVec > 0)){
    sps <- rep(0, length=length(mSetObj$dataSet$cls));
    clsVec <- as.character(mSetObj$dataSet$cls)
    grpnms <- names(shapeVec);
    for(i in 1:length(grpnms)){
      sps[clsVec == grpnms[i]] <- shapeVec[i];
    }
    shapes <- sps;
  }else{
    if(show.name | grey.scale){
      shapes <- as.numeric(mSetObj$dataSet$cls)+1;
    }else{
      shapes <- rep(19, length(mSetObj$dataSet$cls));
    }
  }
  return(shapes);
}

GetColorSchema <- function(mSetObj=NA, grayscale=F){
  
  mSetObj <- .get.mSet(mSetObj);
  # test if total group number is over 9
  grp.num <- length(levels(mSetObj$dataSet$cls));
  
  if(grayscale){
    dist.cols <- colorRampPalette(c("grey90", "grey30"))(grp.num);
    lvs <- levels(mSetObj$dataSet$cls);
    colors <- vector(mode="character", length=length(mSetObj$dataSet$cls));
    for(i in 1:length(lvs)){
      colors[mSetObj$dataSet$cls == lvs[i]] <- dist.cols[i];
    }
  }else if(grp.num > 9){
    pal12 = c("#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99",
              "#E31A1C", "#FDBF6F", "#FF7F00", "#CAB2D6", "#6A3D9A",
              "#FFFF99", "#B15928");
    dist.cols <- colorRampPalette(pal12)(grp.num);
    lvs <- levels(mSetObj$dataSet$cls);
    colors <- vector(mode="character", length=length(mSetObj$dataSet$cls));
    for(i in 1:length(lvs)){
      colors[mSetObj$dataSet$cls == lvs[i]] <- dist.cols[i];
    }
  }else{
    if(exists("colVec") && !any(colVec =="#NA") ){
      cols <- vector(mode="character", length=length(mSetObj$dataSet$cls));
      clsVec <- as.character(mSetObj$dataSet$cls)
      grpnms <- names(colVec);
      for(i in 1:length(grpnms)){
        cols[clsVec == grpnms[i]] <- colVec[i];
      }
      colors <- cols;
    }else{
      colors <- as.numeric(mSetObj$dataSet$cls)+1;
    }
  }
  return (colors);
}

#'Remove folder
#'@description Remove folder
#'@param folderName Input name of folder to remove
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
#'
RemoveFolder<-function(folderName){
  a<-system(paste("rm",  "-r", folderName), intern=T);
  if(!length(a)>0){
    AddErrMsg(paste("Could not remove file -", folderName));
    return (0);
  }
  return(1);
}

#'Remove file
#'@description Remove file
#'@param fileName Input name of file to remove
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
RemoveFile<-function(fileName){
  if(file.exists(fileName)){
    file.remove(fileName);
  }
}

#'Clear folder and memory
#'@description Clear the current folder and objects in memory
#'@param mSetObj Input the name of the created mSetObj (see InitDataObjects)
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
ClearUserDir<-function(mSetObj=NA){
  mSetObj <- .get.mSet(mSetObj);
  # remove physical files
  unlink(dir(), recursive=T);
  mSetObj$dataSet <- mSetObj$analSet <- list();
  gc();
  return(.set.mSet(mSetObj));
}

#'Retrieve last command from the Rhistory.R file
#'@description Fetches the last command from the Rhistory.R file
#'@param regexp Retrieve last command from Rhistory file
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
GetCMD<-function(regexp){
  # store all lines into a list object
  all.lines<-readLines("Rhistory.R");
  
  all.matches<-grep(regexp, all.lines, value=T);
  if(length(all.matches)==0){
    return(NULL);
  }else{
    # only return the last command
    return(all.matches[length(all.matches)]);
  }
}

#'Compute sum of squares (SSQ) for each row of a matrix which may have NA
#'@description Columns have labels cl=consecutive integers
#'note: this is desgined for ASCA parition data
#'in which Within group (WSS) is zero, so, we only need TSS
#'@param x Input X
#'@param cl Input the columns
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)

Get.tss<-function(x, cl){
  
  K <- max(cl) - min(cl) + 1
  tvar <- apply(x, 1, var.na);
  tn <- apply(!is.na(x), 1, sum);
  wvar <- matrix(0, nrow(x), K);
  wn <- matrix(0, nrow(x), K);
  
  for(i in (1:K)) {
    if(sum(cl == (i + min(cl) - 1)) == 1){
      wvar[, i] <- 0;
      wn[, i] <- 1;
    }
    
    if(sum(cl == (i + min(cl) - 1)) > 1) {
      wvar[, i] <- apply(x[, cl == (i + min(cl) - 1)], 1, var.na);
      wn[, i] <- apply(!is.na(x[, cl == (i + min(cl) - 1)]), 1, sum);
    }
  }
  
  WSS <- apply(wvar * (wn - 1), 1, sum.na)
  TSS <- tvar * (tn - 1)
  
  return(TSS);
}

# Memory functions
ShowMemoryUse <- function(..., n=20) {
  save.image("TestMem.RData");
  print(.ls.objects(..., order.by="Size", decreasing=TRUE, head=TRUE, n=n));
  print(warnings());
}

#'Perform utilities for cropping images
#'@description Obtain the full path to convert (from imagemagik)
#'for cropping images
#'@author Jeff Xia\email{jeff.xia@mcgill.ca}
#'McGill University, Canada
#'License: GNU GPL (>= 2)
GetConvertFullPath<-function(){
  path <- system("which convert", intern=TRUE);
  if((length(path) == 0) && (typeof(path) == "character")){
    print("Could not find convert in the PATH!");
    return("NA");
  }
  return(path);
}

# need to obtain the full path to convert (from imagemagik) for cropping images
GetBashFullPath<-function(){
  path <- system("which bash", intern=TRUE);
  if((length(path) == 0) && (typeof(path) == "character")){
    print("Could not find bash in the PATH!");
    return("NA");
  }
  return(path);
}

#'Converts xset object from XCMS to mSet object for MetaboAnalyst
#'@description This function converts processed raw LC/MS data from XCMS 
#'to a usable data object (mSet) for MetaboAnalyst. The immediate next step following using this 
#'function is to perform a SanityCheck, and then further data processing and analysis can continue.
#'@param xset The name of the xcmsSet object created.
#'@param dataType The type of data, either list (Compound lists), conc (Compound concentration data), 
#'specbin (Binned spectra data), pktable (Peak intensity table), nmrpeak (NMR peak lists), mspeak (MS peak lists), 
#'or msspec (MS spectra data).
#'@param analType Indicate the analysis module to be performed: stat, pathora, pathqea, msetora, msetssp, msetqea, ts, 
#'cmpdmap, smpmap, or pathinteg.
#'@param paired Logical, is data paired (T) or not (F).
#'@param format Specify if samples are paired and in rows (rowp), unpaired and in rows (rowu),
#'in columns and paired (colp), or in columns and unpaired (colu).
#'@param lbl.type Specify the data label type, either discrete (disc) or continuous (cont).
#'@export

XSet2MSet <- function(xset, dataType, analType, paired=F, format, lbl.type){
  
  data <- xcms::groupval(xset, "medret", "into");
  data2 <- rbind(class= as.character(phenoData(xset)$class), data);
  rownames(data2) <- c("group", paste(round(groups(xset)[,"mzmed"], 3), round(groups(xset)[,"rtmed"]/60, 1), sep="/"));
  write.csv(data2, file="PeakTable.csv");
  mSet <- InitDataObjects("dataType", "analType", paired)
  mSet <- Read.TextData(mSet, "PeakTable.csv", "format", "lbl.type")
  print("mSet successfully created...")
  return(.set.mSet(mSetObj));
}

#'Get fisher p-values
#'@param numSigMembers Number of significant members
#'@param numSigAll Number of all significant features
#'@param numMembers Number of members
#'@param numAllMembers Number of all members
#'@export
GetFisherPvalue <- function(numSigMembers, numSigAll, numMembers, numAllMembers){
  z <- cbind(numSigMembers, numSigAll-numSigMembers, numMembers-numSigMembers, numAllMembers-numMembers-numSigAll+numSigMembers);
  z <- lapply(split(z, 1:nrow(z)), matrix, ncol=2);
  z <- lapply(z, fisher.test, alternative = 'greater');
  p.values <- as.numeric(unlist(lapply(z, "[[", "p.value"), use.names=FALSE));
  return(p.values);
}


