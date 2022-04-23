function GetFilesByDate() {
  var arrFileIDs = [];

  var Threshold = new Date().getTime()-3600*1000*24*7;
    // 30 is the number of days 
    //(3600 seconds = 1 hour, 1000 milliseconds = 1 second, 24 hours = 1 day and 30 days is the duration you wanted
    //needed in yr-month-day format

  var CullDate = new Date(Threshold);
  var strCullDate = Utilities.formatDate(CullDate, "GMT", "yyyy-MM-dd");
  console.info(strCullDate);

  var FileID = "";
  var FileName = "";

  //Create an array of file ID's by date criteria
  var files = DriveApp.searchFiles(
     'modifiedDate < "' + strCullDate + '"');

  while (files.hasNext()) {
    var file = files.next();
    var FileID = file.getId();
    var FileName = file.getName();

    if (FileName.indexOf('.mp4') > -1 ) {
    arrFileIDs.push(FileID);
    console.info('FileID: ' + FileID);
    console.info('Last Updated: ' + file.getLastUpdated());
    console.info('Filename: ' + FileName);
    }
  }

  return arrFileIDs;
  console.info('FileIDs Array: ' + arrFileIDs);
};

function DeleteFilesByDate() {
  var arrayIDs = GetFilesByDate();

  for (var i=0; i < arrayIDs.length; i++) {
    console.info('arrayIDs[i]: ' + arrayIDs[i]);
    //This deletes a file without needing to move it to the trash
    var DelResponse = Drive.Files.remove(arrayIDs[i]);
  }
};