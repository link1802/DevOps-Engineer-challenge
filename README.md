# DevOps-Engineer-challenge
## Requisitos

1. Crear una proyecto el cual debe tener dos subnets, una privada y una pública.
2. Lanzar una grupo de auto escalado con dos compute instances dentro de la subnet privada.
3. Instalar nginx y mostrar la ip privada.
4. Crear un balanceador en la subnet pública.
5. Crear una politica de auto escalado con los siguientes párametros.: scale in : CPU utilization > 40%, scale out : CPU Utilization < 20%

Para este proyecto, se creo un script en Terraform, para poder automatizar la creacion de los sigientes elementos:

- creacion de proyecto
- creacion de una maquina virtual en blanco
- creacion de 2 Subredes (una publica (proxy) y una privada(lan))
- preparacion de una plantilla para el grupo de instancias
- creacion de script para agregar la ip lan al archivo de nginx (desde el Metadata de la instancia)
- creacion de un balanceador que mantendra a 1 instancia si el consumo de CPU es menor del 20% y aumentara a 2 en caso de aumentar a 40% de uso del CPU
- al final el script entrega la ip a apuntar para poder realizar una consulta en curl y este devolvera la ip pirvada de la instancia

para poder correr el archivo se debe realizar los siguientes comandos en la consola de GCP (google cloud plataform):

```terraform
terraform init
terraform plan -out"default.tfplan"
terraform apply -var="proyect_billing_id=000000-000000-000000"
```

donde el valor de "proyect_billing_id" debe ser el id de facturacion de la cuenta, en caso de no proporcionarlo, la API de google, no se habilitara y por lo tanto no podra ejecutar el script
para una mejor referencia de como obtener este valor, vea la siguiente [liga](https://console.cloud.google.com/billing?_ga=2.229969052.1664475333.1652314216-1631168250.1652309941) ahi debera ver el ID a agregar a la variable

------------------------------------------------------------------------------------------------------------------------------------------------------------
## Requirements

1. Create a project which must have two subnets, one private and one public.
2. Launch an auto scaling group with two compute instances within the private subnet.
3. Install nginx and show the private ip.
4. Create a balancer on the public subnet.
5. Create an auto scaling policy with the following parameters: scale in : CPU utilization > 40%, scale out : CPU Utilization < 20%

For this project, a script was created in Terraform, in order to automate the creation of the following elements:

- project creation
- create a blank virtual machine
- creation of 2 subnets (one public (proxy) and one private (lan))
- preparation of a template for the group of instances
- script creation to add the lan ip to the nginx file (from the Metadata of the instance)
- creation of a balancer that will keep 1 instance if the CPU consumption is less than 20% and will increase to 2 in case of increasing the CPU usage to 40%
- at the end the script delivers the ip to point to be able to perform a query in curl and this will return the private ip of the instance

In order to run the file, the following commands must be carried out in the GCP console (google cloud platform):

```terraform
terraform init
terraform plan -out"default.tfplan"
terraform apply -var="proyect_billing_id=000000-000000-000000"
```

where the value of "project_billing_id" must be the billing id of the account, if you do not provide it, the google API will not be enabled and therefore you will not be able to execute the script
For a better reference on how to obtain this value, see the following [link](https://console.cloud.google.com/billing?_ga=2.229969052.1664475333.1652314216-1631168250.1652309941) there you should see the ID to add to the variable
