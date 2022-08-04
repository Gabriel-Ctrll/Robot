*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium        auto_close=${False}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    Collections
Library    RPA.Dialogs
Library    OperatingSystem
#Library    RPA.Robocloud.Secrets
Library    RPA.Robocorp.Vault

*** Variables ***

${url}            https://robotsparebinindustries.com/#/robot-order

${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output

${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip
${csv_url}        https://robotsparebinindustries.com/orders.csv




*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Directory Cleanup

    #Get The Program Author Name From Our Vault
    ${username}=    Get The User Name
    Open the robot order website

    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form           ${row}
        Wait Until Keyword Succeeds     10x     2s    Preview the robot
        Wait Until Keyword Succeeds     10x     2s    Submit The Order
        ${orderid}  ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=                Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file     IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***

 Open the robot order website
        Open Available Browser    ${url}
           
Directory Cleanup
    Log To console      Cleaning up content from previous test runs

    # O comando archive não criará isso automaticamente, portanto, precisamos garantir que o diretório esteja lá
    # Criar diretório não nos dará um erro se o diretório já existir.
    
    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}

    Empty Directory     ${img_folder}
    Empty Directory     ${pdf_folder}


Get orders
    
    #Captura do arquivo csv e download


    Download    url=${csv_url}         target_file=${orders_file}    overwrite=True
    ${table}=   Read table from CSV    path=${orders_file}
    [Return]    ${table}


Close the annoying modal
    # Definir variáveis ​​locais para os elementos da interface do usuário
    Set Local Variable              ${btn_yep}        //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button           ${btn_yep}


    
Fill the form
    [Arguments]     ${myrow}

    # Extraia os valores do dicionário
    Set Local Variable    ${order_no}   ${myrow}[Order number]
    Set Local Variable    ${head}       ${myrow}[Head]
    Set Local Variable    ${body}       ${myrow}[Body]
    Set Local Variable    ${legs}       ${myrow}[Legs]
    Set Local Variable    ${address}    ${myrow}[Address]

    # Definir variáveis ​​locais para os elementos da interface do usuário
    # O UID "legs" muda o tempo todo, então este usa um
    # xpath absoluto. Eu prefiro variáveis ​​locais sobre 
    #"Atribuir ID ao elemento", pois o último não parece
    # para poder usar uma referência XPath completa

    Set Local Variable      ${input_head}       //*[@id="head"]
    Set Local Variable      ${input_body}       body
    Set Local Variable      ${input_legs}       xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable      ${input_address}    //*[@id="address"]
    Set Local Variable      ${btn_preview}      //*[@id="preview"]
    Set Local Variable      ${btn_order}        //*[@id="order"]
    Set Local Variable      ${img_preview}      //*[@id="robot-preview-image"]

    # Insira os dados
    # existem situações em que um campo ainda não está visível
    # No entanto, assume-se que todos os elementos de entrada são visíveis
    # quando o primeiro elemento for tornado visível.
    # Uma abordagem ainda mais cuidadosa resultaria em verificar se, por exemplo,
   
    Wait Until Element Is Visible   ${input_head}
    Wait Until Element Is Enabled   ${input_head}
    Select From List By Value       ${input_head}           ${head}

    Wait Until Element Is Enabled   ${input_body}
    Select Radio Button             ${input_body}           ${body}

    Wait Until Element Is Enabled   ${input_legs}
    Input Text                      ${input_legs}           ${legs}
    Wait Until Element Is Enabled   ${input_address}
    Input Text                      ${input_address}        ${address}

Preview the robot
    
    Set Local Variable                ${bnt_preview}    //*[@id="preview"]
    Set Local Variable                ${img_preview}    //*[@id="robot-preview"]
    Click Button                      ${bnt_preview}
    Wait Until Element Is Visible     ${img_preview}


Submit The Order

    Set Local Variable    ${bnt_order}        //*[@id="order"]
    Set Local Variable    ${lbl_recept}       //*[@id="receipt"]


    Click Button                   ${bnt_order}    
    Page Should Contain Element    ${lbl_recept}    

Take a screenshot of the robot
    
    Set Local Variable    ${lbl_orderid}        xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_robot}            //*[@id="robot-preview"]


    Wait Until Element Is Visible   ${img_robot}
    Wait Until Element Is Visible   ${lbl_orderid} 
    


    ${orderid}=            Get Text            //*[@id="receipt"]/p[1]


    Set Local Variable    ${fully_qualified_img_filename}    ${img_folder}${/}${orderid}.png 



    Sleep    1
    Log To Console    Capturing Screenshot to ${fully_qualified_img_filename}

    Capture Element Screenshot    ${img_robot}    ${fully_qualified_img_filename}
    
    [Return]     ${orderid}     ${fully_qualified_img_filename}





Go to order another robot

    Set Local Variable    ${btn_order_another_robot}        //*[@id="order-another"]
    Click Button          ${btn_order_another_robot} 


Log Out And Close The Browser
    Close Browser    


Create a ZIP file of the receipts
    Archive Folder With Zip    ${pdf_folder}    ${zip_file}        recursive=True  include=*.pdf


Store the receipt as a PDF file
    [Arguments]        ${ORDER_NUMBER}
    
    Wait Until Element Is Visible   //*[@id="receipt"]
    Log To Console                  Printing ${ORDER_NUMBER}

    ${order_receipt_html}=            Get Element Attribute    //*[@id="receipt"]  outerHTML

    Set Local Variable              ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}

    [Return]    ${fully_qualified_pdf_filename}




Embed the robot screenshot to the receipt PDF file
    
     [Arguments]     ${IMG_FILE}     ${PDF_FILE}
    
    Log To Console                  Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}

    Open Pdf    ${PDF_FILE}

    @{myfiles}=        Create List        ${IMG_FILE}:x=0,y=0
    


    Add Files To PDF    ${myfiles}    ${PDF_FILE}     ${True}

Get The Program Author Name From Our Vault
     Log To Console          Getting Secret from our Vault
    ${secret}=                Get Secret     credentials      
     Log                     ${secret}[username] wrote this program for you      console=yes


Get The User Name
    Add heading             I am your RoboCorp Order Genie
   Add text input          myname    label=What is thy name, oh sire?     placeholder=Give me some input here
    ${result}=              Run dialog
   [Return]                ${result.myname}


Display the success dialog
    [Arguments]   ${USER_NAME}
    Add icon      Success
    Add heading   Your orders have been processed
    Add text      Dear ${USER_NAME} - all orders have been processed. Have a nice day!
    Run dialog    title=Success



