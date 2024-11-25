//+------------------------------------------------------------------+
//|                                                    DKLicense.mqh |
//|                                                  Denis Kislitsyn |
//|                                             https://kislitsyn.me |
//+------------------------------------------------------------------+
#property copyright "Denis Kislitsyn"
#property link      "https://kislitsyn.me"

#include "..\Common\md5hash.mqh"

string LicenseToString(const long aAccount, const datetime aDate, const string aSalt) {
  string query = StringFormat("%I64u:%s", aAccount, TimeToString(aDate, TIME_DATE));
  string quetySalted = query + aSalt;
  
  CMD5Hash md5;
  return query + ":" + md5.Hash(query);
}

bool IsLicenseValid(string aLicenseKeyToCheck, const long aAccount, const string aSalt) {
  string arr[];
  if (StringSplit(aLicenseKeyToCheck, StringGetCharacter(":", 0), arr) != 3) return false;
  
  datetime licenseKeyDT = StringToTime(arr[1]);
  if (TimeCurrent()> licenseKeyDT) return false;
  
  return LicenseToString(aAccount, licenseKeyDT, aSalt) == aLicenseKeyToCheck;
}
