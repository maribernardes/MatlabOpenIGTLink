%% Receiver function example
function testReceiveMessage()
    clc; close all;

    % Set IP socket and number of messages (N) to receive
    N = 1;
    sock = igtlConnect('127.0.0.1', 18944);
    receiver = OpenIGTLinkMessageReceiver(sock, @onRxStatusMessage, @onRxStringMessage, @onRxTransformMessage, @onRxPointMessage, @onRxImageMessage);
    for i=1:N+1 % not counting first STATUS message (N+1)
        receiver.readMessage();
    end
    igtlDisconnect(sock);
end

%% Callback when STATUS message is received and processed
% Currently, only prints received value
function onRxStatusMessage(deviceName, text)
    disp(['Received STATUS message ', deblank(deviceName),  text]);
end

%% Callback when STRING message is received and processed
% Currently, only prints received value
function onRxStringMessage(deviceName, text)
    disp(['Received STRING message: ', deblank(deviceName), ' = ', text]);
end

%% Callback when TRANSFORM message is received and processed
% Currently, only prints received value
function onRxTransformMessage(deviceName, transform)
    disp('Received TRANSFORM message: ');
    disp([deblank(deviceName),  ' = ']);
    disp(transform);
end

%% Callback when POINT message is received and processed
% Currently, only prints received value
function onRxPointMessage(deviceName, array)
  disp('Received POINT message: ');
  disp([deblank(deviceName),  ' = ']);
  disp(array);
end

%% Callback when IMAGE message is received and processed
% Currently, only prints received value
function onRxImageMessage(deviceName, image)
  disp('Received IMAGE message: ');
  disp([deblank(deviceName),  ' = ']);
  disp(['Image Origin = [', num2str(image.origin), ']']);
  disp('Image Orientation = ');
  disp(num2str(image.orientation));
  igtlShowImage(image, 1);
  save('RTDose.mat', 'image'); 
end