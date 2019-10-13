public with sharing class pdExpenseFromFreee {
    /**
    * 取引(支出)を取得する
     */
    @future(callout=true) 
    public static void getExpenseInfo(Integer months) {
        // MotionBoard上の経費明細データを削除する
        eraseExpense();

        // 会社情報を取得する
        Integer companyId = getCompany();

        // 勘定科目情報を取得する
        List<AccountInfo> lstAccountInfo = getAccountInfo(companyId);

        // 半年分の経費明細を取得する
        Date startDate;
        String expenseDetail = '種別,ID,計上日,発生日,勘定科目,金額,備考\r\n';
        for(Integer i=0 ; i<months ; i++){
            startDate = Date.today().toStartOfMonth().addMonths(i * (-1));
            Date endDate = startDate.addMonths(1).addDays(-1);

            expenseDetail += getExpense(companyId, lstAccountInfo, startDate, endDate);
        }

        // 経費明細データをMotionBoardに送信する
        sendExpense(expenseDetail, false, null);

        // MotionBoardの経費明細スナップショットを実行する
        execSnapshot();

        // 経費明細データを削除する
        deleteExpense();

        // 経費明細レコードを作成する
        FreeeExpenseDetail__c fed = new FreeeExpenseDetail__c();
        fed.StartDate__c = startDate;
        insert fed;

        // 経費明細CSVファイルを添付ファイルとして保存する
        AttatchFile(fed.Id, expenseDetail);
    }

    /**
    * 経費明細データをMotionBoardに送信する
     */
    private static void sendExpense(String ExpenseData, Boolean IsErase, Date StartDate) {
        // カスタムメタデータからMotionBoardに関する情報を取得する
        MotionBoard__mdt mb = [SELECT Url__c,TenantId__c,UserId__c,Password__c from MotionBoard__mdt WHERE DeveloperName='pitadigi' LIMIT 1];

        // データを消去する場合は計上日が開始日以外の種別を-----delete-----にする
        if (IsErase) {
            // Freee経費明細データを改行で分割する
            String[] lstExpenseData = ExpenseData.split('\r\n');

            for(Integer i=1 ; i<lstExpenseData.size() ; i++) {
                String[] lstDetail = lstExpenseData[i].split(',');
                // 分割後の個数が7個でなければ7個にする(備考がなくなるケースあり)
                if(lstDetail.size() != 7) {
                    lstDetail.add('');
                }
                if (Date.valueOf(lstDetail[2].replace('/', '-')) != StartDate) {
                    lstDetail[0] = '-----delete-----';
                }
                lstExpenseData[i] = String.join(lstDetail, ',');
            }

            ExpenseData = String.join(lstExpenseData, '\r\n');
        }

        // 経費明細CSVをPOSTするリクエストを作成する
        HttpRequest req = new HttpRequest();
        String Boundary = '------------' + String.valueOf(DateTime.now().getTime());
        String Url = mb.Url__c + 'csv/put/shared/';
        Url += EncodingUtil.urlEncode('ぴたデジ', 'UTF-8');
        Url += '/' + EncodingUtil.urlEncode('経費', 'UTF-8');
        Url += '/' + EncodingUtil.urlEncode('経費明細.csv', 'UTF-8');
        req.setEndpoint(Url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'multipart/form-data;boundary=' + Boundary);
        String Body = setParam(Boundary, 'tenant', mb.TenantId__c);
        Body += setParam(Boundary, 'id', mb.UserId__c);
        Body += setParam(Boundary, 'pw', mb.Password__c);
        Body += '--'+Boundary+'\r\nContent-Disposition: form-data; name="uploadFile"; filename="expene.csv";\r\nContent-Type: text/csv\r\n\r\n' + 
        ExpenseData + '\r\n--' + Boundary + '--';
        req.setBody(Body);
        req.setTimeout(10 * 1000);

        // MotionBoardにリクエストを送信する
        Http http = new Http();
        HttpResponse res = http.send(req);

        // エラーが返ってきたら例外をスローする
        if (res.getStatusCode() != 200) {
            throw new OtherException(getApiErrorMessage(res.getBody()));
        }
    }

    /**
    * MotionBoardにPOSTするためのパラメータを設定する
    */
    private static String setParam(String Boundary, String Param, String Value) {
        String ret = '--' + boundary+'\r\n'
        + 'Content-Disposition: form-data; name="' + Param + '"'
        + '\r\n\r\n' + Value + '\r\n';
        return ret;
    }

    /**
    * MotionBoardの経費明細スナップショットを実行する
    */
    private static void execSnapshot () {
        // カスタムメタデータからMotionBoardに関する情報を取得する
        MotionBoard__mdt mb = [SELECT Url__c,TenantId__c,UserId__c,Password__c from MotionBoard__mdt WHERE DeveloperName='pitadigi' LIMIT 1];

        // 経費明細スナップショット実行をPOSTするリクエストを作成する
        HttpRequest req = new HttpRequest();
        String Url = mb.Url__c + 'snapshot/task/exec/';
        Url += EncodingUtil.urlEncode('経費明細', 'UTF-8');
        req.setEndpoint(Url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String Body = 'tenant=' + EncodingUtil.urlEncode(mb.TenantId__c, 'UTF-8');
        Body += '&id=' + EncodingUtil.urlEncode(mb.UserId__c, 'UTF-8');
        Body += '&pw=' + EncodingUtil.urlEncode(mb.Password__c, 'UTF-8');
        req.setBody(Body);
        req.setTimeout(10 * 1000);

        // MotionBoardにリクエストを送信する
        Http http = new Http();
        HttpResponse res = http.send(req);

        // エラーが返ってきたら例外をスローする
        if (res.getStatusCode() != 200) {
            throw new OtherException(getApiErrorMessage(res.getBody()));
        }
    }

    /**
    * Freee経費明細委IDから経費明細CSVデータを取得する
    */
    private static String getExpenseCSV(Id fedId) {
        // 添付ファイル情報を取得する
        ContentDocumentLink cdl = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:fedId limit 1];
        if (cdl != null) {
            ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId=:cdl.ContentDocumentId AND IsLatest=true];
            return cv.VersionData.toString();
        }

        return null;
    }

    /**
    * 経費明細データを削除する
    * 経費明細データの削除は以下のように行う
    * ・経費明細CSVの開始日の月以外の種別を----delete-----に変更する
    * ・MotionBoardに経費明細.csvとしてアップロードする
    * ・MotionBoardのスナップショット「経費明細」を実行する
    * 　(MotionBoardのスナップショット機能の自動削除で種別が-----delete-----のレコードを削除する)
    * ・経費明細データを削除する
     */
    private static void eraseExpense() {
        // 経費明細情報を取得する(複数あることを想定して開始日降順で取得する)
        List<FreeeExpenseDetail__c> lstFed = [SELECT Id,StartDate__c FROM FreeeExpenseDetail__c ORDER BY StartDate__c DESC];
        if (lstFed.size() != 0) {
            // 経費明細CSVデータを取得する
            String ExpenseCSV = getExpenseCSV(lstFed[0].Id);
            // 経費明細CSVを消去モードで送信する
            sendExpense(ExpenseCSV, true, lstFed[0].StartDate__c);
            // 経費明細スナップショットを実行する
            execSnapshot();
        }

    }

     /**
     * 経費明細情報を削除する
    */
    private static void deleteExpense() {
        // 経費明細データを削除する
        List<FreeeExpenseDetail__c> lstFed = [SELECT Id FROM FreeeExpenseDetail__c];
        if (lstFed.size() != 0) {
            delete lstFed;
        }
    }

    private static void AttatchFile(Id recordId, String content) {
        // ドキュメントを作成する
        ContentVersion cv = new ContentVersion();
        // ファイルはSalesforce上に保存
        cv.ContentLocation = 'S';
        // ファイル名
        cv.PathOnClient = 'expense.csv';
        // ファイルタイトル
        cv.Title = '経費明細';
        // ファイルの内容
        cv.VersionData = Blob.valueOf(content);
        insert cv;

        // 登録したファイルのドキュメントIDを取得する
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

        // レコードとドキュメントをリンクする
        ContentDocumentLink cde = new ContentDocumentLink();
        // リンクするドキュメントID
        cde.ContentDocumentId = docId;
        // 添付ファイルとしてリンクするオブジェクトのレコードID
        cde.LinkedEntityId = recordId;
        cde.ShareType = 'V';
        insert cde;
    }

    /**
    * 会社情報を取得する
     */
    private static Integer getCompany() {    
        // 会社情報を取得する
        Http http = new Http();
        String path = 'callout:Freee/companies';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setMethod('GET');

        HttpResponse res = http.send(req);
        // 会社情報が返ってきたらIIDと名称を設定する
        if (res.getStatusCode() == 200) {
            Map<String, Object> mapCompany = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> lstCompany = (List<Object>)mapCompany.get('companies');
            if (lstCompany.size() == 0) {
                throw new OtherException('会社情報が取得できません');
            }
            else {
                return (Integer)((Map<String, Object>)lstCompany[0]).get('id');
            }
        }
        // エラーで返ってきたら例外をスローする
        else {
            throw new OtherException(getApiErrorMessage(res.getBody()));
        }
    }

    /**
    * 勘定科目情報を取得する
     */
    private static List<AccountInfo> getAccountInfo(Integer companyId) {
        // 勘定科目情報を取得する
        Http http = new Http();
        String path = 'callout:Freee/account_items';
        String parameters = 'company_id=' + companyId;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(path + '?' + parameters);
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
        else {
            throw new OtherException(getApiErrorMessage(res.getBody()));
        }

        return lstAccoutList;
    }

    /**
    * 経費明細を取得する
    */
    private static String getExpense(Integer companyId, List<AccountInfo> lstAccountInfo, Date startDate, Date endDate) {
        // 期間を指定して経費明細を取得する
        Http http = new Http();
        String path = 'callout:Freee/deals';
        String parameters = 'company_id=' + companyId;
        parameters += '&type=expense';
        parameters += '&start_issue_date=' + startDate.format().replace('/', '-');
        parameters += '&end_issue_date=' + endDate.format().replace('/', '-');
        parameters += '&limit=100';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(path + '?' + parameters);
        req.setMethod('GET');

        HttpResponse res = http.send(req);

        // 正常に返って来たら経費明細CSVを作成する
        String expenseDetail = '';
        if(res.getStatusCode() == 200) {
            System.debug(res.getBody());
            Map<String, Object> mapBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> lstDeals = (List<Object>)mapBody.get('deals');
            for(Object deal : lstDeals) {
                Map<String, Object> mapDeal = (Map<String, Object>)deal;
                List<Object> lstDetail = (List<Object>)mapDeal.get('details');
                for(Object detail : lstDetail) {
                    Map<String, Object> mapDetail = (Map<String, Object>)detail;

                    // 経費明細データをCSV形式で作成する
                    // 種別
                    expenseDetail += '-----data-----,';
                    // ID
                    expenseDetail += String.valueOf((Integer)mapDetail.get('id')) + ',';
                    // 計上日
                    expenseDetail += Date.valueOf((String)mapDeal.get('issue_date')).toStartOfMonth().format() + ',';
                    // 発生日
                    expenseDetail += Date.valueOf((String)mapDeal.get('issue_date')).format() + ',';
                    // 勘定科目
                    expenseDetail += getAccountName(lstAccountInfo, (Integer)mapDetail.get('account_item_id')) + ',';
                    // 金額
                    expenseDetail += String.valueOf((Integer)mapDetail.get('amount')) + ',';
                    // 備考
                    String description = (String)mapDetail.get('description');
                    if (description == null) {
                        description = '';
                    }
                    expenseDetail += description.replace(',', '、').replace('¥"', '”');
                    expenseDetail += '\r\n';
                }
            }
        }
        else {
            throw new OtherException(getApiErrorMessage(res.getBody()));
        }
        
        return expenseDetail;
    }

    /**
    * 勘定科目リストから指定IDの勘定科目名を返す
     */
    private static String getAccountName(List<AccountInfo> lstAccountInfo, Integer Id) {
        String ret = null;
        for(AccountInfo ai : lstAccountInfo) {
            if(ai.Id == Id) {
                ret = ai.Name;
                break;
            }
        }

        return ret;
    }

    /**
    * エラーメッセージを設定する
     */
    private static String getApiErrorMessage(String body) {
        System.debug(body);
        String errorMessage = 'Freee APIでエラーが発生しました\r\n';
        if (body != null && body.length() != 0) {
            Map<String, Object> mapError = (Map<String, Object>)JSON.deserializeUntyped(body);
            List<Object> lstError = (List<Object>)(mapError.get('errors'));
            for(Object mapErrorContent : lstError) {
                List<Object> lstMessage = (List<Object>)((Map<String, Object>)mapErrorContent).get('messages');
                for(Object message : lstMessage) {
                    errorMessage += message.toString() + '\r\n';
                }
            }
        }

        return errorMessage;
    }

    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    private class AccountInfo {
        Integer Id;
        String Name;
    }
}
