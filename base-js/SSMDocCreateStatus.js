var AWS = require('aws-sdk');
exports.handler =  function(event, context, callback) {
  getStatusDoc(event.instanceId,callback)
}

function getStatusDoc(instanceId,callback) {
  var ssm = new AWS.SSM();
   var params = {
    Name:"workshop-tools",
    DocumentFormat: "JSON"
   }
   ssm.getDocument(params,function(err, data) {
    if (err) {
      console.log("Status of SSM Doc " + err);
      callback(err,null)
    } else {
      console.log("Status of SSM Doc " + data.Status);
      callback(null,data)
    }
   });
}