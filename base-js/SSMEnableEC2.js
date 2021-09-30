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
  var instanceId = "";
  var ec2 = new AWS.EC2();
  ec2.describeInstances(params,function(err, data) {
    if (err)
    console.log(err, err.stack);
    else {
      instanceId = data.Reservations[0].Instances[0].InstanceId;
      var assocInstanceProfile = data.Reservations[0].Instances[0].IamInstanceProfile;
      console.log("Instances Identified " + instanceId);
      associateIamInstanceProfile(ec2,assocInstanceProfile,instanceId);
      setTimeout(function() {rebootInstances(ec2,instanceId);},process.env.Timeout1);
    }
  });
  callback(null,instanceId);
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