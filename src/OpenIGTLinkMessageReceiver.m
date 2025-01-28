% OpenIGTLink server that executes the received string commands
function receiver = OpenIGTLinkMessageReceiver(sock, onRxStatusMsg, onRxStringMsg, onRxTransformMsg, onRxPointMsg)
    global onRxStatusMessage onRxStringMessage onRxTransformMessage onRxPointMessage;
    global socket;
    global timeout;
    onRxStatusMessage = onRxStatusMsg;
    onRxStringMessage = onRxStringMsg;
    onRxTransformMessage = onRxTransformMsg;
    onRxPointMessage = onRxPointMsg;
    socket = sock;
    timeout = 500;
    receiver.readMessage = @readMessage;
end

% Process message content. Handle message content according with their types
function [name, data] = readMessage()
    global onRxStatusMessage onRxStringMessage onRxTransformMessage onRxPointMessage;
    msg = ReadOpenIGTLinkMessage();
    messageType = char(msg.dataTypeName);
    messageType = deblank(messageType);
    if strcmpi(messageType, 'STATUS')
        [name, data] = handleStatusMessage(msg, onRxStatusMessage);
    elseif strcmpi(messageType, 'STRING')
        [name, data] = handleStringMessage(msg, onRxStringMessage);
    elseif strcmpi(messageType, 'TRANSFORM')
        [name, data] = handleTransformMessage(msg, onRxTransformMessage);
    elseif strcmpi(messageType, 'POINT')
        [name, data] = handlePointMessage(msg, onRxPointMessage);
    else
        disp(['Currently unsupported message type:', messageType])
    end
end

%% Message content decoding (type specific)

% STATUS Message content
% Obs: 3DSlicer is currently sending all zero bytes status messages (code = 0 - invalid packet)
% Commented out message parsing for that reason
function [name, message] = handleStatusMessage(msg, onRxStatusMessage)
    if (length(msg.content)<30)
        disp('Error: STATUS message received with incomplete contents')
        return
    end
    % code = convertUint8Vector(msg.content(1:2), 'uint16');
    % subCode = convertUint8Vector(msg.content(3:10), 'int64');
    % errorName = char(msg.content(11:30));
    % message = char(msg.content(31:length(msg.content)));
    message = ''; % No message for now
    name = msg.deviceName;
    onRxStatusMessage(msg.deviceName, message);
end

% STRING Message content
function [name, message] = handleStringMessage(msg, onRxStringMessage)
    if (length(msg.content)<5)
        disp('Error: STRING message received with incomplete contents')
        msg.string='';
        return
    end
    strMsgEncoding = convertUint8Vector(msg.content(1:2), 'uint16');
    if (strMsgEncoding~=3)
        disp(['Warning: STRING message received with unknown encoding ',num2str(strMsgEncoding)])
    end
    strMsgLength = convertUint8Vector(msg.content(3:4), 'uint16');
    message = char(msg.content(5:4+strMsgLength));
    name = msg.deviceName;
    onRxStringMessage(name, message);
end

% TRANSFORM Message content
function [name, transform] = handleTransformMessage(msg, onRxTransformMessage)
    transform = diag([1 1 1 1]);
    k=1;
    for i=1:4
        for j=1:3
            transform(j,i) = convertUint8Vector(msg.content(4*(k-1) +1:4*k), 'single');
            k = k+1;
        end
    end
    name = msg.deviceName;
    onRxTransformMessage(name , transform);
end

% POINT Message
function [name, pointList] = handlePointMessage(msg, onRxPointMessage)
    pointDataSize = 136;
    numPoints = floor((length(msg.content))/pointDataSize);
    % Preallocate structure array
    points(numPoints) = struct('name', '', 'group', '', 'RGBA', [], 'XYZ', [], 'diameter', [], 'owner', ''); 
    pointList = zeros(numPoints, 3);
    for i = 1:numPoints
        % Compute offset for this point
        offset = (i-1) * pointDataSize; 
        % Extract data using the computed offset
        points(i).name = char(msg.content(offset + (1:64)));  % Name field (64 bytes)
        points(i).group = char(msg.content(offset + (65:96))); % Group field (32 bytes)
        points(i).RGBA = [msg.content(offset + 97), msg.content(offset + 98), ...
                          msg.content(offset + 99), msg.content(offset + 100)]; % RGBA (4 bytes)
        points(i).XYZ = [convertUint8Vector(msg.content(offset + (101:104)), 'single'), ...
                         convertUint8Vector(msg.content(offset + (105:108)), 'single'), ...
                         convertUint8Vector(msg.content(offset + (109:112)), 'single')]; % XYZ (3 × 4 bytes)
        points(i).diameter = convertUint8Vector(msg.content(offset + (113:116)), 'single'); % Diameter (4 bytes)
        points(i).owner = char(msg.content(offset + (117:136))); % Owner (20 bytes)
        % Store XYZ in pointList
        pointList(i,:) = points(i).XYZ;
    end
    name = msg.deviceName;
    onRxPointMessage(name , pointList);
end

%% General message decoding
% http://openigtlink.org/protocols/v2_header.html
% https://openigtlink.org/protocols/v3_proposal.html

% Parse OpenIGTLink message header
function msg = ParseOpenIGTLinkMessageHeader(rawMsg)
    msg.versionNumber = convertUint8Vector(rawMsg(1:2), 'uint16');
    msg.dataTypeName = char(rawMsg(3:14));
    msg.deviceName = char(rawMsg(15:34));
    msg.timestamp = convertUint8Vector(rawMsg(35:42), 'uint64');
    msg.bodySize = convertUint8Vector(rawMsg(43:50), 'uint64');
    msg.bodyCrc = convertUint8Vector(rawMsg(51:58), 'uint64');
end

% Parse OpenIGTLink message body
function msg = ParseOpenIGTLinkMessageBody(msg)
    if (msg.versionNumber==1) % Body has only content (Protocol v1 and v2)
        msg.content = msg.body;     % Copy data from body to content
        msg = rmfield(msg, 'body'); % Remove the old field 'body'
        msg.extHeaderSize = [];
        msg.metadataHeaderSize = [];
        msg.metadataSize = [];
        msg.msgID = [];
        msg.metadataNumberKeys = [];
        msg.metadata = [];
    elseif (msg.versionNumber==2) % Body has extended_header, content and metadata (Protocol v3)
        % Extract extended_header
        msg.extHeaderSize = convertUint8Vector(msg.body(1:2), 'uint16');
        msg.metadataHeaderSize = convertUint8Vector(msg.body(3:4), 'uint16');
        msg.metadataSize = convertUint8Vector(msg.body(5:8), 'uint32');
        msg.msgID = convertUint8Vector(msg.body(9:12), 'uint32');
        % Extract content
        contentSize = msg.bodySize - (uint64(msg.extHeaderSize) + uint64(msg.metadataHeaderSize) + uint64(msg.metadataSize));
        msg.content = msg.body(13:12+contentSize);
        % Extract metadata
        msg.metadataNumberKeys = convertUint8Vector(msg.body(13+contentSize:14+contentSize), 'uint16');
        msg.metadata = msg.body(15+contentSize:length(msg.body));
        msg = rmfield(msg, 'body'); % Remove the old field 'body'
    end
end

% Receive message header and body and check for completeness
function msg = ReadOpenIGTLinkMessage()
    global timeout;
    openIGTLinkHeaderLength = 58;
    % Get message header
    headerData = ReadWithTimeout(openIGTLinkHeaderLength, timeout);
    % Check is complete header was received
    if (length(headerData)==openIGTLinkHeaderLength)
        % Get Message header
        msg = ParseOpenIGTLinkMessageHeader(headerData);
        % Get Message body
        msg.body = ReadWithTimeout(msg.bodySize, timeout);  
        % TODO: Check CRC64
        % Separate msg.body into extended_header, content, meta_data
        msg = ParseOpenIGTLinkMessageBody(msg);
    else
        error('ERROR: Timeout while waiting receiving OpenIGTLink message header')
    end
end    

% Buffer expected number of bytes with timeout
function data = ReadWithTimeout(requestedDataLength, timeoutSec)
    import java.net.Socket
    import java.io.*
    import java.net.ServerSocket
    global socket;
    data = zeros(1, requestedDataLength, 'uint8'); % preallocate to improve performance
    signedDataByte = int8(0);
    bytesRead = 0;
    while (bytesRead < requestedDataLength)    
        % Computing (requestedDataLength-bytesRead) is an int64 operation, which may not be available on Matlab R2009 and before
        int64arithmeticsSupported =~ isempty(find(strcmp(methods('int64'),'minus'),1));
        if int64arithmeticsSupported
            % Full 64-bit arithmetics
            bytesToRead = min(socket.inputStream.available, requestedDataLength-bytesRead);
        else
            % Fall back to floating point arithmetics
            bytesToRead = min(socket.inputStream.available, double(requestedDataLength)-double(bytesRead));
        end  
        if (bytesRead == 0 && bytesToRead > 0)
            % starting to read message header
            tstart = tic;
        end
        for i = bytesRead+1:bytesRead+bytesToRead
            signedDataByte = DataInputStream(socket.inputStream).readByte;
            if signedDataByte>=0
                data(i) = signedDataByte;
            else
                data(i) = bitcmp(-signedDataByte,'uint8')+1;
            end
        end            
        bytesRead = bytesRead+bytesToRead;
        if (bytesRead>0 && bytesRead<requestedDataLength)
            % check if the reading of the header has timed out yet
            timeElapsedSec=toc(tstart);
            if(timeElapsedSec>timeoutSec)
                % timeout, it should not happen
                % remove the unnecessary preallocated elements
                data = data(1:bytesRead);
                break
            end
        end
    end
end

%% Auxiliar functions

% Conversion from array of bytes to given type
function result = convertUint8Vector(uint8Vector, targetType)
    % Ensure the input is a uint8 vector
    if ~isa(uint8Vector, 'uint8')
        error('Input must be of type uint8.');
    end
    % Use typecast to convert uint8 to the specified target type
    result = swapbytes(typecast(uint8Vector, targetType));
end