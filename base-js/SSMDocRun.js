var AWS = require('aws-sdk');
exports.handler =  function(event, context, callback) {
  execInstallScripts(event.instanceId,callback)
}

function execInstallScripts(instanceId,callback) {
  console.log("Executing installation for " + instanceId);
  var ssm = new AWS.SSM();
  var params = {
    DocumentName: 'AWS-ConfigureAWSPackage',
    DocumentVersion: '1',
    CloudWatchOutputConfig: {
        CloudWatchOutputEnabled: true
    },
    Parameters: {
      action: ['Install'],
      installationType:["Uninstall and reinstall"],
      name: ["workshop-tools"],
      version:[""]
    },
    InstanceIds: [instanceId],
    TimeoutSeconds: 60
  }
  ssm.sendCommand(params,function(err, data) {
    if (err) {
      callback(err,null)
    } else {
      callback(null,data.Status)
    }
  });
}