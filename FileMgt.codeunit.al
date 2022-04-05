codeunit 50100 SDFileMgt
{
    procedure Upload()
    var
        FilePath: Text;
        OutStr: OutStream;
        Instr: InStream;
        SDFiles: Record "SD Files";
    begin
        File.UploadIntoStream('Upload File', '', '', FilePath, Instr);
        SDFiles.ID := CreateGuid();
        SDFiles.Content.CreateOutStream(OutStr);
        CopyStream(OutStr, Instr);
        SDFiles.Insert();
    end;

    procedure Download()
    var
        Instr: InStream;
        SDFiles: Record "SD Files";
        Filename: Text;
    begin
        SDFiles.FindFirst();
        SDFiles.CalcFields(Content);
        SDFiles.Content.CreateInStream(Instr);
        File.DownloadFromStream(Instr, 'Download File', '', '', Filename);
    end;

    procedure CreateAndDownloadDataFile(Item: Record Item)
    var
        Instr: InStream;
        Outstr: OutStream;
        Filename: Text;
        TempBlob: Codeunit "Temp Blob";
        CR, LF : char;
    begin
        CR := 13;
        LF := 10;
        Filename := 'ItemDataFile.txt';
        TempBlob.CreateOutStream(Outstr);
        Outstr.WriteText('No: ' + item."No." + CR + LF);
        Outstr.WriteText('Description: ' + Item.Description + CR + LF);
        TempBlob.CreateInStream(Instr);
        DownloadFromStream(Instr, '', '', '', Filename);
    end;

    //Table 4151 Persistent Blob
    procedure ImportBlobToPersistentBlob(var Filename: Text; var PID: BigInteger)
    var
        PersistentBlob: Codeunit "Persistent Blob";
        Instr: InStream;
        SDFiles: Record "SD Files";
    begin
        if UploadIntoStream('File upload', '', '', Filename, Instr) then begin
            PID := PersistentBlob.Create();
            PersistentBlob.CopyFromInStream(PID, Instr);
            //Store the blob reference to the original table
            SDFiles.BlobID := PID;
            SDFiles.Insert();
        end;
    end;

    procedure FindAndExportPersistentBlob(var Filename: Text; var PID: BigInteger)
    var
        PersistentBlob: Codeunit "Persistent Blob";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Instr: InStream;
    begin
        if PersistentBlob.Exists(PID) then begin
            TempBlob.CreateOutStream(OutStr);
            PersistentBlob.CopyToOutStream(PID, OutStr);
            TempBlob.CreateInStream(Instr);
            DownloadFromStream(Instr, '', '', '', Filename)
        end;
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
        end;
    end;



    procedure ExportContactsAsCSV()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        ExportContact: Xmlport "Export Contact";
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        ExportContact.SetDestination(OutStr);
        ExportContact.Export();
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        FileName := 'ContactList.txt';
        DownloadFromStream(InStr, 'Export', '', '', FileName);
    end;

    //Uploading Item pictures
    procedure ImportItemPictures(Item: Record Item)
    var
        Filename: Text;
        Instr: InStream;
    begin
        if UploadIntoStream('Item picture uploading', '', '', Filename, Instr) then begin
            Clear(Item.Picture);
            Item.Picture.ImportStream(Instr, Filename);
            Item.Modify(true);
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