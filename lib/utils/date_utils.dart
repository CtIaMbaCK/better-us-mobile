import 'package:intl/intl.dart';

class DateTimeUtils {

  static DateTime parseFromApi(String dateTimeString) {
    try {
      // Parse string thành UTC DateTime
      DateTime utcTime = DateTime.parse(dateTimeString).toUtc();

      // Convert sang local time của thiết bị
      return utcTime.toLocal();
    } catch (e) {
      print('Error parsing datetime: $e');
      return DateTime.now();
    }
  }

  /// Format datetime thành chuỗi để hiển thị
  static String formatMessageTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('HH:mm').format(localTime);
  }

  
  static String formatLastMessageTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTime);

    if (difference.inDays == 0) {
     
      return DateFormat('HH:mm').format(localTime);
    } else if (difference.inDays == 1) {
  
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      
      return DateFormat('EEEE', 'vi_VN').format(localTime);
    } else {
      
      return DateFormat('dd/MM').format(localTime);
    }
  }

 
  static String formatFullDateTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(localTime);
  }


  static String formatDate(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('dd/MM/yyyy').format(localTime);
  }

  
  static String formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    return DateFormat('HH:mm').format(localTime);
  }

  // format time cho message
  static String formatRelativeTime(String dateTimeStr) {
    try {
      final dateTime = parseFromApi(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return formatDate(dateTime);
      }
    } catch (e) {
      return 'Vừa xong';
    }
  }
}
