
module.exports = function(robot) {

    robot.router.post ('/hubot/message/:room', function (req, res) {
        robot.messageRoom( req.params.room, req.body.message );
        res.send('OK');
    });
    
};
