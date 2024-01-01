fn BuildCustomErrorMessages() [5]CustomErrorMessage {
    var errors = [5]CustomErrorMessage{
        GetCustomErrorMessage(error.FileIsEmpty, @constCast("The file we're trying to parse is empty.\n")),
        GetCustomErrorMessage(error.FileOpenError, @constCast("The file we're trying to parse can not be opened.\n")),
        GetCustomErrorMessage(error.FileNotFound, @constCast("The file we're trying to parse can not be found.\n")),
        GetCustomErrorMessage(error.ErrorOutOfMemory, @constCast("We ran out of memory.\n")),
        GetCustomErrorMessage(error.DeleteFileError, @constCast("Failed to delete file for some reason.")),
        // GetCustomErrorMessage(error.ErrorSharingViolation, @constCast("Sharing violation.\n")),
        // GetCustomErrorMessage(error.ErrorPathAlreadyExists, @constCast("Path already exists.\n")),
        // GetCustomErrorMessage(error.ErrorAccessDenied, @constCast("Access denied.\n")),
        // GetCustomErrorMessage(error.ErrorPipeBusy, @constCast("Pipe busy.\n")),
        // GetCustomErrorMessage(error.ErrorNameTooLong, @constCast("Name too long.\n")),
        // GetCustomErrorMessage(error.ErrorInvalidUtf8, @constCast("Invalid UTF8.\n")),
        // GetCustomErrorMessage(error.ErrorBadPathName, @constCast("Bad path name.\n")),
        // GetCustomErrorMessage(error.ErrorUnexpected, @constCast("Unexpected error.\n")),
        // GetCustomErrorMessage(error.ErrorNetworkNotFound, @constCast("Network not found.\n")),
        // GetCustomErrorMessage(error.ErrorInvalidHandle, @constCast("Invalid handle.\n")),
        // GetCustomErrorMessage(error.ErrorSymLinkLoop, @constCast("SymLink loop.\n")),
        // GetCustomErrorMessage(error.ErrorProcessFdQuotaExceeded, @constCast("Process FD quota exceeded.\n")),
        // GetCustomErrorMessage(error.ErrorSystemFdQuotaExceeded, @constCast("System FD quota exceeded.\n")),
        // GetCustomErrorMessage(error.ErrorNoDevice, @constCast("No device.\n")),
        // GetCustomErrorMessage(error.ErrorSystemResources, @constCast("System resources.\n")),
        // GetCustomErrorMessage(error.ErrorFileTooBig, @constCast("File too big.\n")),
        // GetCustomErrorMessage(error.ErrorIsDir, @constCast("Is directory.\n")),
        // GetCustomErrorMessage(error.ErrorNoSpaceLeft, @constCast("No space left.\n")),
        // GetCustomErrorMessage(error.ErrorNotDir, @constCast("Not directory.\n")),
        // GetCustomErrorMessage(error.ErrorDeviceBusy, @constCast("Device busy.\n")),
        // GetCustomErrorMessage(error.ErrorFileLocksNotSupported, @constCast("File locks not supported.\n")),
        // GetCustomErrorMessage(error.ErrorFileBusy, @constCast("File busy.\n")),
        // GetCustomErrorMessage(error.ErrorWouldBlock, @constCast("Would block.\n")),
        // GetCustomErrorMessage(error.ErrorInputOutput, @constCast("Input output.\n")),
        // GetCustomErrorMessage(error.ErrorOperationAborted, @constCast("Operation aborted.\n")),
        // GetCustomErrorMessage(error.ErrorBrokenPipe, @constCast("Broken pipe.\n")),
        // GetCustomErrorMessage(error.ErrorConnectionResetByPeer, @constCast("Connection reset by peer.\n")),
        // GetCustomErrorMessage(error.ErrorConnectionTimedOut, @constCast("Connection timed out.\n")),
        // GetCustomErrorMessage(error.ErrorNotOpenForReading, @constCast("Not open for reading.\n")),
        // GetCustomErrorMessage(error.ErrorNetNameDeleted, @constCast("Net name deleted.\n")),
        // GetCustomErrorMessage(error.ErrorStreamTooLong, @constCast("Stream too long.\n")),
    };
    return errors;
}
const CustomErrorTypes = error{
    FileIsEmpty,
    FileOpenError,
    FileNotFound,
    ErrorOutOfMemory,
    DeleteFileError,
};

fn GetCustomErrorMessage(comptime T: CustomErrorTypes, comptime message: []u8) CustomErrorMessage {
    var customError = CustomErrorMessage{
        .err = T,
        .customErrorMessage = message,
    };
    return customError;
}
const CustomErrorMessage = struct {
    err: CustomErrorTypes,
    customErrorMessage: []u8,
};

pub fn FetchCustomErrorMessage(errorType: anyerror, all_custom_errors: [5]CustomErrorMessage) []u8 {
    for (all_custom_errors) |custom_err| {
        if (@TypeOf(custom_err) == @TypeOf(errorType)) {
            return custom_err.customErrorMessage;
        }
    }
    return @constCast("Could not find error message.");
}

pub const AllCustomErrorMessages = BuildCustomErrorMessages();
