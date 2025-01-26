clc;
close all;

% Start connection
igtlConnection = igtlConnect('127.0.0.1',18944);
sender = OpenIGTLinkMessageSender(igtlConnection);

% Send a POINT message
pointList = [0, 0, 0;
            0.5, 0.5, 0.2;
            1.2, 1.4, 3.2];
sender.WriteOpenIGTLinkPointMessage('TEST_POINT2', pointList);

% % Send a STRING message
% msg = 'Hello World!';
% sender.WriteOpenIGTLinkStringMessage('String Matlab', msg);

% % Send multiple TRANSFORM messages
% theta = 0;
% for t=1:15
%     theta = theta + deg2rad(30)*t;
%     matrix = [cos(theta), -sin(theta), 0, 0;
%           sin(theta), cos(theta),  0, 0;
%           0,          0,           1, 0;
%           0,          0,           0, 1];
%     sender.WriteOpenIGTLinkTransformMessage('Transform Matlab', matrix);
%     pause(1)
% end

% Close connection
igtlDisconnect(igtlConnection);

