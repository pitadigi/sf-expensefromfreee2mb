public with sharing class pdExpenseFromFreee {
    /**
    * 取引(支出)を取得する
     */
    static public void getExpenseInfo() {
        // 勘定科目情報を取得する
        List<AccountInfo> lstAccountInfo = getAccountInfo();
    }

    /**
    * 勘定科目情報を取得する
     */
    static private List<AccountInfo> getAccountInfo() {
        // 勘定科目情報を取得する
        Http http = new Http();
        String path = 'callout:Freee/account_item';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setMethod('GET');

        HttpResponse res = http.send(req);

        // 正常に返って来たらオブジェクトに設定する
        List<AccountInfo> lstAccoutList = new List<AccountInfo>();
        if (res.getStatusCode() == 200) {
            Map<String, Object> mapBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> lstBody = (List<Object>)mapBody.get('account_items');
            for(Object item : lstBody) {
                Map<String, Object> mapItem = (Map<String, Object>)item;
                AccountInfo ai = new AccountInfo();
                ai.Id = (Integer)mapItem.get('id');
                ai.Name = (String)mapItem.get('name');
                lstAccoutList.add(ai);
            }
        }

        return lstAccoutList;
    }

    private class AccountInfo {
        Integer Id;
        String Name;
    }
}
