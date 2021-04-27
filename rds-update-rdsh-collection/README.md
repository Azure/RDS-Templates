# Update Remote Desktop Session Collection to the new template image

This template updates RDSH servers in the existing session host collection with a new updated template image. The URI for the image is provided as a template parameter.

This template deploys the following resources:
- `<numberOfRdshInstances>` new virtual machines as RDSH servers

This template does the following:
- Creates new RDSH instances from a given template image and adds them to the collection;
- Puts old RDSH servers in Drain mode to prevent new user connections;
- Notifies any logged on RD users that their sessions will soon be terminated due to collection maintenance;
- Logs off existing users from old RDSH instances after a given timeout (`<userLogoffTimeoutInMinutes>` parameter).

**Note:** This template does **not** delete or deallocate old RDSH instances, so you may still incur compute charges. Any old virtual machine instances will have to be deleted manually.

Click the button below to deploy:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmmarch%2Fazure-quickstart-templates%2Fmaster%2Frds-update-rdsh-collection%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fmmarch%2Fazure-quickstart-templates%2Fmaster%2Frds-update-rdsh-collection%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
