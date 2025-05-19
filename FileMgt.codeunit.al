codeunit 50100 SDFileMgt
{
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpload()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpload(var SDFiles: Record "SD Files"; FilePath: Text)
    begin
    end;

    procedure Upload()
    var
        FilePath: Text;
        OutStr: OutStream;
        Instr: InStream;
        SDFiles: Record "SD Files";
    begin
        OnBeforeUpload();
        
        File.UploadIntoStream('Upload File', '', '', FilePath, Instr);
        SDFiles.ID := CreateGuid();
        SDFiles.Content.CreateOutStream(OutStr);
        CopyStream(OutStr, Instr);
        SDFiles.Insert();
        
        OnAfterUpload(SDFiles, FilePath);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownload(var SDFiles: Record "SD Files")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDownload(var SDFiles: Record "SD Files"; Filename: Text)
    begin
    end;

    procedure Download()
    var
        Instr: InStream;
        SDFiles: Record "SD Files";
        Filename: Text;
    begin
        SDFiles.FindFirst();
        
        OnBeforeDownload(SDFiles);
        
        SDFiles.CalcFields(Content);
        SDFiles.Content.CreateInStream(Instr);
        File.DownloadFromStream(Instr, 'Download File', '', '', Filename);
        
        OnAfterDownload(SDFiles, Filename);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAndDownloadDataFile(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateAndDownloadDataFile(var Item: Record Item; Filename: Text)
    begin
    end;

    procedure CreateAndDownloadDataFile(Item: Record Item)
    var
        Instr: InStream;
        Outstr: OutStream;
        Filename: Text;
        TempBlob: Codeunit "Temp Blob";
        CR, LF : char;
    begin
        OnBeforeCreateAndDownloadDataFile(Item);
        
        CR := 13;
        LF := 10;
        Filename := 'ItemDataFile.txt';
        TempBlob.CreateOutStream(Outstr);
        Outstr.WriteText('No: ' + item."No." + CR + LF);
        Outstr.WriteText('Description: ' + Item.Description + CR + LF);
        TempBlob.CreateInStream(Instr);
        DownloadFromStream(Instr, '', '', '', Filename);
        
        OnAfterCreateAndDownloadDataFile(Item, Filename);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportBlobToPersistentBlob(var Filename: Text; var PID: BigInteger)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportBlobToPersistentBlob(var Filename: Text; var PID: BigInteger; var SDFiles: Record "SD Files")
    begin
    end;

    //Table 4151 Persistent Blob
    procedure ImportBlobToPersistentBlob(var Filename: Text; var PID: BigInteger)
    var
        PersistentBlob: Codeunit "Persistent Blob";
        Instr: InStream;
        SDFiles: Record "SD Files";
    begin
        OnBeforeImportBlobToPersistentBlob(Filename, PID);
        
        if UploadIntoStream('File upload', '', '', Filename, Instr) then begin
            PID := PersistentBlob.Create();
            PersistentBlob.CopyFromInStream(PID, Instr);
            //Store the blob reference to the original table
            SDFiles.BlobID := PID;
            SDFiles.Insert();
            
            OnAfterImportBlobToPersistentBlob(Filename, PID, SDFiles);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindAndExportPersistentBlob(var Filename: Text; var PID: BigInteger)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindAndExportPersistentBlob(var Filename: Text; var PID: BigInteger)
    begin
    end;

    procedure FindAndExportPersistentBlob(var Filename: Text; var PID: BigInteger)
    var
        PersistentBlob: Codeunit "Persistent Blob";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Instr: InStream;
    begin
        OnBeforeFindAndExportPersistentBlob(Filename, PID);
        
        if PersistentBlob.Exists(PID) then begin
            TempBlob.CreateOutStream(OutStr);
            PersistentBlob.CopyToOutStream(PID, OutStr);
            TempBlob.CreateInStream(Instr);
            DownloadFromStream(Instr, '', '', '', Filename)
        end;
        
        OnAfterFindAndExportPersistentBlob(Filename, PID);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveReportAsPDF()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveReportAsPDF(var Customer: Record Customer; var EmailMsg: Codeunit "Email Message")
    begin
    end;

    procedure SaveReportAsPDF()
    var
        OutStr: OutStream;
        Recref: RecordRef;
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        Customer: Record Customer;
        //Mail message attachment
        EmailMsg: Codeunit "Email Message";
        Email: Codeunit Email;
        Instr: InStream;
        Recipients: List of [Text];
        CCs: List of [Text];
    begin
        OnBeforeSaveReportAsPDF();
        
        TempBlob.CreateOutStream(OutStr);
        Customer.SetRange("No.", '10000', '50000');
        IF Customer.FindSet() then begin
            Recref.GetTable(Customer);
            if Report.SaveAs(119, '', ReportFormat::Pdf, OutStr, Recref) then
                FileMgt.BLOBExport(TempBlob, 'CustomerSalesList.pdf', true)
            else
                Message('unable to download the report.');

            //Mail attachments
            Recipients.Add('sd@demiliani.com');
            EmailMsg.Create(Recipients, 'SUBJECT', 'Body', false);
            TempBlob.CreateInStream(Instr);
            EmailMsg.AddAttachment('Sales.pdf', 'PDF', Instr);
            Email.Send(EmailMsg);
            
            OnAfterSaveReportAsPDF(Customer, EmailMsg);
        end;
    end;



    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportContactsAsCSV()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExportContactsAsCSV(FileName: Text)
    begin
    end;

    procedure ExportContactsAsCSV()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        ExportContact: Xmlport "Export Contact";
    begin
        OnBeforeExportContactsAsCSV();
        
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        ExportContact.SetDestination(OutStr);
        ExportContact.Export();
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        FileName := 'ContactList.txt';
        DownloadFromStream(InStr, 'Export', '', '', FileName);
        
        OnAfterExportContactsAsCSV(FileName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportItemPictures(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportItemPictures(var Item: Record Item; Filename: Text)
    begin
    end;

    //Uploading Item pictures
    procedure ImportItemPictures(Item: Record Item)
    var
        Filename: Text;
        Instr: InStream;
    begin
        OnBeforeImportItemPictures(Item);
        
        if UploadIntoStream('Item picture uploading', '', '', Filename, Instr) then begin
            Clear(Item.Picture);
            Item.Picture.ImportStream(Instr, Filename);
            Item.Modify(true);
            
            OnAfterImportItemPictures(Item, Filename);
        end;
    end;

    procedure ExportItemPicture2(Item: Record Item);
    var
        TenantMedia: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        FileMgmt: Codeunit "File Management";
        PicInStream: InStream;
        FinalDownloadStream: Instream;
        ZipStream: OutStream;
        Index: Integer;
        FileName: Text;
        DataCompression: Codeunit "Data Compression";
    begin
        if Item.Picture.Count() = 0 then
            exit;

        TempBlob.CreateOutStream(ZipStream);
        DataCompression.CreateZipArchive();
        for Index := 1 to Item.Picture.Count() do
            if TenantMedia.Get(Item.Picture.Item(Index)) then begin
                TenantMedia.calcfields(Content);
                if TenantMedia.Content.HasValue() then begin
                    FileName := StrSubstNo('%1_Image_%2.jpg', Item.TableCaption(), Index);
                    TenantMedia.Content.CreateInStream(PicInstream);
                    DataCompression.AddEntry(PicInStream, FileName);
                end;
            end;
        DataCompression.SaveZipArchive(TempBlob);
        TempBlob.CreateInStream(FinalDownloadStream);
        FileName := StrSubstNo('Item_%1.zip', Item.Description);
        DownloadFromStream(FinalDownloadStream, 'Download zip-archive', '', '', FileName);
    end;


    procedure CreateJSON(var SDFiles: Record "SD Files"): JsonObject
    var
        json: JsonObject;
        Instr: InStream;
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        Outstr: OutStream;
        Filename: Text;
        JsonText, BlobJsonBase64 : Text;
        token: JsonToken;
    begin
        json.Add('ID', SDFiles.ID);
        SDFiles.CalcFields(SDFiles.Content);
        SDFiles.Content.CreateInStream(Instr);
        json.Add('Blob', Base64Convert.ToBase64(Instr));
        //Output
        Filename := 'SDFile.json';
        TempBlob.CreateOutStream(Outstr);
        Outstr.Write(Format(json));
        TempBlob.CreateInStream(Instr);
        DownloadFromStream(Instr, '', '', '', Filename);

        //And what about uploading from JSON?
        Instr.Read(JsonText);
        json.ReadFrom(JsonText);
        json.Get('Content', token);
        if token.IsValue() then
            BlobJsonBase64 := token.AsValue().AsText();
        SDFiles.Content.CreateOutStream(Outstr);
        Base64Convert.FromBase64(BlobJsonBase64, Outstr);
        SDFiles.Modify();
    end;


}