function openIGTMessageSender = OpenIGTLinkMessageSender(sock)
    global socket;
    socket = sock;
    openIGTMessageSender.WriteOpenIGTLinkStringMessage = @WriteOpenIGTLinkStringMessage;
    openIGTMessageSender.WriteOpenIGTLinkTransformMessage = @WriteOpenIGTLinkTransformMessage;
    openIGTMessageSender.WriteOpenIGTLinkPointMessage = @WriteOpenIGTLinkPointMessage;
end

%% Prepare STRING specific message fields and call WriteOpenIGTLinkMessage
function result = WriteOpenIGTLinkStringMessage(deviceName, msgString, protocolVersion)
    % Use Protocol v3 by default
    if nargin < 3
        protocolVersion = 3;
    end
    % STRING specific header
    msg.dataTypeName = uint8(padString('STRING', 12));
    msg.deviceName = uint8(padString(deviceName, 20));
    % STRING content
    msgString = [uint8(msgString)];
    encoding = convertToUint8Vector(3, 'uint16');
    stringLength = convertToUint8Vector(length(msgString), 'uint16');
    msg.content = [encoding, stringLength, msgString];
    % STRING medatada (might be optional)
    numberKeys = convertToUint8Vector(2, 'uint16');
    key1 = uint8('MRMLNodeName');
    value1 = uint8('Text');
    keySize1 = convertToUint8Vector(length(key1), 'uint16');
    valueEncod1 = convertToUint8Vector(3, 'uint16');
    valueSize1 = convertToUint8Vector(length(value1), 'uint32');
    key2 = uint8('Status');
    value2 = uint8('OK');
    keySize2 = convertToUint8Vector(length(key2), 'uint16');
    valueEncod2 = convertToUint8Vector(3, 'uint16');
    valueSize2 = convertToUint8Vector(length(value2), 'uint32');
    metadataHeader = [numberKeys, keySize1, valueEncod1, valueSize1, keySize2, valueEncod2, valueSize2];
    metadataValues = [key1, value1, key2, value2];
    msg.metadataHeaderSizeInt = length(metadataHeader);
    msg.metadataSizeInt = length(metadataValues);
    msg.metadata = [metadataHeader, metadataValues];
    result = WriteOpenIGTLinkMessage(msg, protocolVersion);
end

%% Prepare TRANSFORM specific message fields and call WriteOpenIGTLinkMessage
function result = WriteOpenIGTLinkTransformMessage(deviceName, transform, protocolVersion)
    % Use Protocol v3 by default
    if nargin < 3
        protocolVersion = 3;
    end
    % TRANSFORM specific header
    msg.dataTypeName = uint8(padString('TRANSFORM', 12));
    msg.deviceName = uint8(padString(deviceName, 20));
    % TRANSFORM content
    msg.content = [];
    transform = single(transform); % Convert to float32
    for i=1:4
        for j=1:3
            msg.content = [msg.content, convertToUint8Vector(transform(j,i),'single')];
        end    
    end
    % TRANSFORM medatada (might be optional)
    numberKeys = convertToUint8Vector(1, 'uint16');
    key1 = uint8('MRMLNodeName');
    value1 = uint8('LinearTransform');
    keySize1 = convertToUint8Vector(length(key1), 'uint16');
    valueEncod1 = convertToUint8Vector(3, 'uint16');
    valueSize1 = convertToUint8Vector(length(value1), 'uint32');
    metadataHeader = [numberKeys, keySize1, valueEncod1, valueSize1];
    metadataValues = [key1, value1];
    msg.metadataHeaderSizeInt = length(metadataHeader);
    msg.metadataSizeInt = length(metadataValues);
    msg.metadata = [metadataHeader, metadataValues];
    result = WriteOpenIGTLinkMessage(msg, protocolVersion);
end

%% Prepare POINT specific message fields and call WriteOpenIGTLinkMessage
function result = WriteOpenIGTLinkPointMessage(deviceName, pointList, protocolVersion)
    % Use Protocol v3 by default
    if nargin < 3
        protocolVersion = 3;
    end
    % POINT specific header
    msg.dataTypeName = uint8(padString('POINT', 12));
    msg.deviceName = uint8(padString(deviceName, 20));
    % POINT content
    msg.content = [];
    numPoints = size(pointList,1);
    pointList = single(pointList);
    for i = 1:numPoints
        name = uint8(padString([deviceName, '-', num2str(i)],64));
        group = uint8(padString('Selected', 32));
        rgba = uint8([255, 127,	127, 255]);
        X = convertToUint8Vector(pointList(i,1), 'single');
        Y = convertToUint8Vector(pointList(i,2), 'single');
        Z = convertToUint8Vector(pointList(i,3), 'single');
        diameter =  convertToUint8Vector(single(0), 'single');
        owner = uint8(padString('', 20));
        msg.content = [msg.content, name, group, rgba, X, Y, Z, diameter, owner];
    end
    % POINT medatada (might be optional)
    numberKeys = convertToUint8Vector(2, 'uint16');
    key1 = uint8('MRMLNodeName');
    value1 = uint8('MarkupsFiducial');
    keySize1 = convertToUint8Vector(length(key1), 'uint16');
    valueEncod1 = convertToUint8Vector(3, 'uint16');
    valueSize1 = convertToUint8Vector(length(value1), 'uint32');
    key2 = uint8('Status');
    value2 = uint8('OK');
    keySize2 = convertToUint8Vector(length(key2), 'uint16');
    valueEncod2 = convertToUint8Vector(3, 'uint16');
    valueSize2 = convertToUint8Vector(length(value2), 'uint32');
    metadataHeader = [numberKeys, keySize1, valueEncod1, valueSize1, keySize2, valueEncod2, valueSize2];
    metadataValues = [key1, value1, key2, value2];
    msg.metadataHeaderSizeInt = length(metadataHeader);
    msg.metadataSizeInt = length(metadataValues);
    msg.metadata = [metadataHeader, metadataValues];
    result = WriteOpenIGTLinkMessage(msg, protocolVersion);
end

%% Assemble message and push to socket
function result = WriteOpenIGTLinkMessage(msg, protocolVersion)
    global socket;
    import java.net.Socket
    import java.io.*
    import java.net.ServerSocket
    % Use Protocol v3 by default
    if nargin < 3
        protocolVersion = 3;
    end
    % Define message fields
    timestamp = convertToUint8Vector(igtlTimestampNow(), 'uint64');
    if protocolVersion < 3     
        % Protocols v1 and v2 do not have ext_header and metadata
        versionNumber = convertToUint8Vector(1, 'uint16');
        % Define body
        bodySize = convertToUint8Vector(length(msg.content), 'uint64');
        body = msg.content;
        bodyCrc = igtlComputeCrc(body); 
    else
        % Include metadata fields (since Protocol v3)
        versionNumber = convertToUint8Vector(2, 'uint16');
        % If no metadata included in msg by specific message function
        if ~isfield(msg, 'metadata') || isempty(msg.metadata)
            msg.metadataHeaderSizeInt = 2;
            msg.metadataSizeInt = 0;
            msg.metadata = convertToUint8Vector(0, 'uint16'); % numberKeys=0
        end
        % Prepare extended_header fields (since Protocol v3)
        extHeaderSize = convertToUint8Vector(12, 'uint16');
        metadataHeaderSize = convertToUint8Vector(msg.metadataHeaderSizeInt, 'uint16');
        metadataSize = convertToUint8Vector(msg.metadataSizeInt, 'uint32');
        msgID = convertToUint8Vector(0, 'uint32');
        extendedHeader = [extHeaderSize, metadataHeaderSize, metadataSize, msgID];
        % Define body
        bodySize = convertToUint8Vector(length(msg.content) + 12 + msg.metadataHeaderSizeInt + msg.metadataSizeInt, 'uint64'); % content_size + extHeaderSize + (metadataHeaderSize + metadataSize);
        body = [extendedHeader, msg.content, msg.metadata];
        bodyCrc = igtlComputeCrc(body);
    end

    % Pack message
   
    data = [versionNumber,  msg.dataTypeName,  msg.deviceName, timestamp, bodySize, bodyCrc, body];    
    result = 1;
    try
        DataOutputStream(socket.outputStream).write(uint8(data),0,length(data));
    catch ME
        disp(ME.message)
        result=0;
    end
    try
        DataOutputStream(socket.outputStream).flush;
    catch ME
        disp(ME.message)
        result=0;
    end
    if (result==0)
      disp('Sending OpenIGTLink message failed');
    end
end

%% Auxiliar functions

% Convert number to array of bytes
function result = convertToUint8Vector(value, type)
    % Validate type input
    validTypes = {'int16', 'int32', 'int64', 'uint16', 'uint32', 'uint64', 'single', 'double'};
    if ~ismember(type, validTypes)
        error('Invalid type. Supported types: int16, int32, int64, uint16, uint32, uint64, single, double.');
    end
    % Convert the input value to the specified type
    typedValue = cast(value, type); % Ensures correct data type
    % Use typecast to convert the value into a uint8 vector
    result = typecast(swapbytes(typedValue), 'uint8'); % Make it big endian
end

% Pad strings with empty spaces to achieve array with desired lenght
function paddedStr = padString(str,strLen)
  paddedStr = str(1:min(length(str),strLen));
  paddingLength = strLen-length(paddedStr);
  if (paddingLength>0)
      paddedStr = [paddedStr,zeros(1,paddingLength,'uint8')];
  end
end

% Get current timestamp for stamping message
function timestamp = igtlTimestampNow()
    % timestamp = java.lang.System.currentTimeMillis/1000;
    timestamp = uint64(0);
end