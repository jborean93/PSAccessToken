using System;
using System.ComponentModel;
using System.Management.Automation;

namespace PSAccessToken
{
    internal enum Win32ErrorCode : int
    {
        ERROR_SUCCESS = 0x00000000,
        ERROR_ACCESS_DENIED = 0x00000005,
        ERROR_INVALID_PARAMETER = 0x00000057,
    }

    internal class ErrorHelper
    {
        public static ErrorRecord GenerateWin32Error(Win32Exception exception, string message, string nativeFunction,
            object targetObject = null)
        {
            string errorId = nativeFunction + ",";
            try
            {
                errorId += Enum.GetName(typeof(Win32ErrorCode), exception.NativeErrorCode);
            }
            catch (ArgumentException)
            {
                errorId += String.Format("0x{2:X8}", exception.NativeErrorCode);
            }

            ErrorCategory category = ErrorCategory.NotSpecified;
            switch (exception.NativeErrorCode)
            {
                case (int)Win32ErrorCode.ERROR_ACCESS_DENIED:
                    category = ErrorCategory.PermissionDenied;
                    break;

                case (int)Win32ErrorCode.ERROR_INVALID_PARAMETER:
                    category = ErrorCategory.InvalidArgument;
                    break;
            }

            ErrorRecord record = new ErrorRecord(exception, errorId, (ErrorCategory)category, targetObject);
            string errorMessage = String.Format("{0} ({1} Win32ErrorCode {2} - 0x{2:X8})",
                message, exception.Message, exception.NativeErrorCode);
            record.ErrorDetails = new ErrorDetails(errorMessage);

            return record;
        }
    }
}
