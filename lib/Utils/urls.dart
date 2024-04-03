// String baseURL = 'http://eurdp1-tpl.ddns.net:8080/api/';
String baseURL = 'https://betprowinner.com/api/';
    // 'https://bettingkings.app/api/';
//                http://solutionswave.com/bpro/api/

//////////////  non authenticated apis
String loginURL = '${baseURL}login';
String signUpURL = '${baseURL}register';

String searchURL = '${baseURL}search';
String resetPasswordURL = '${baseURL}resetPassword';

//////////////  authenticated apis
String findUserURL = '${baseURL}user_detail';
String changePasswordURL = '${baseURL}resetPassword';
// String changeUserStatusURL = '${baseURL}changeUserStatus';

String transactionHistoryURL = '${baseURL}transaction_history';

String getBanksNameURL = '${baseURL}get_banks_name';
String withdrawRequestURL = '${baseURL}payment';
String depositRequestURL = '${baseURL}reciept';

String depositSlipURL = '${baseURL}view_transaction';

String withdrawTimeUrl = '${baseURL}getTime';

String getCommission = '${baseURL}get-commission';
// String verifyTransactionURL = '${baseURL}verifyTransaction';
// String transactionRequestURL = '${baseURL}transactionRequest';
