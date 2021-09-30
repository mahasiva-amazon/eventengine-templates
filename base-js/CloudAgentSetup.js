var AWS = require('aws-sdk');
exports.handler =  function(event, context, callback) {
  var params = {
    Filters: [
      {
        Name: 'tag:platform:type',
        Values: [
          "Cloud9"
        ]
      },
      {
        Name: 'instance-state-name',
        Values: ['running']
      }
    ]
  };
  var ec2 = new AWS.EC2();
  ec2.describeInstances(params,function(err, data) {
    if (err)
    console.log(err, err.stack);
    else {
      var instanceId = data.Reservations[0].Instances[0].InstanceId;
      var assocInstanceProfile = data.Reservations[0].Instances[0].IamInstanceProfile;
      console.log("Instances Identified " + instanceId);
      associateIamInstanceProfile(ec2,assocInstanceProfile,instanceId);
      setTimeout(function() {rebootInstances(ec2,instanceId);},process.env.Timeout1);
      setTimeout(function() {createSSMInstallScriptsDocs(instanceId);},process.env.Timeout1);
      setTimeout(function() { console.log("Completed"); }, process.env.Timeout1);
    }
  });

}

function rebootInstances(ec2,instanceId) {
  var params = { InstanceIds: [ instanceId ] };
  ec2.rebootInstances(params, function(err, data) {
    if (err)
      console.log(err, err.stack);
    else
      console.log(data);
  });
}
function associateIamInstanceProfile(ec2,assocInstanceProfile,instanceId) {
  if(!assocInstanceProfile) {
    var params = {
      IamInstanceProfile: {
        Name: 'AllowAllAccessToCloud9EC2'
      },
      InstanceId: instanceId
    };
    ec2.associateIamInstanceProfile(params, function(err, data) {
      if (err)
      console.log(err, err.stack);
      else
      console.log(data);
    });
  }
}
function createSSMInstallScriptsDocs(instanceId) {
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
    if(err)
      console.log("Document Creation Error " + err);
  });
  
  var commandDocAvailable = false;
  var count = 0;
  do {
   params = {
    Name:"workshop-tools",
    DocumentFormat: "JSON"
   }
   ssm.getDocument(params,function(err, data) {
    if (data) {
      console.log("Status of SSM Doc " + data.Status);
      if(data && data.Status == 'Active') {
        setTimeout(function() {
            execInstallScripts(ssm,instanceId)
         },process.env.Timeout3);
      }
    }
   });
   count++;
  }while(!commandDocAvailable && count < 10);
}
function execInstallScripts(ssm,instanceId) {
  console.log("Executing installation for " + instanceId);
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
      setTimeout(function() {
        ssm.sendCommand(params,function(err, data) {
          if(err) {
            console.log(err, err.stack);
            setTimeout(function() {
              ssm.sendCommand(params,function(err, data){
                if(err) {
                  console.log(err, err.stack);
                  setTimeout(function() {ssm.sendCommand(params,function(err, data){});},process.env.Timeout2);
                }
              });
            },process.env.Timeout3);
          }
        });
      },process.env.Timeout4);
      console.log(err, err.stack);
    }
    else {
      console.log("Data " + JSON.stringify(data));
    }
  });
}