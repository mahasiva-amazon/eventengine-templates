var AWS = require('aws-sdk');
exports.handler =  function(event, context, callback) {
  createSSMDoc(event.instanceId);
}

function createSSMDoc(instanceId,callback) {
  var ssm = new AWS.SSM();
  var params = {
    Content: "{\"schemaVersion\": \"2.0\",\"version\": \"1.0.0\",\"packages\": {\"amazon\": {\"_any\": {\"x86_64\": {\"file\": \"install.zip\"}}}},\"files\": {\"install.zip\": {\"checksums\": {\"sha256\": \"" + process.env.InstallModuleSha + "\"}}}}",
    Name:"workshop-tools",
    Attachments: [
      {
        Key: "SourceUrl",
        Values: [process.env.S3ModuleBucket]
      }
    ],
    DocumentFormat: "JSON",
    DocumentType: "Package"
  }
  ssm.createDocument(params,function(err, data) {
    if(err) {
      console.log("Document Creation Error " + err);
      callback(err,null)
    } else {
      callback(null,data.Status)
    }
  });
}