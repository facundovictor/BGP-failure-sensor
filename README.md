# BGP-failure-sensor
BGP's failure sensor. For Quagga's BGP daemon.

Currently working for only 2 BGP neighbors. It can be easily adapted to N.

## Configuration:

1. Alert mail destination:

  ```
  email="administrator@mydomain.com"
  ```

2. First Neighbor
 
  ```
  S_IP="192.0.1.1"
  S_name="Neigh_1"
  ```
  
3. Second Neighbor
  
  ```
  C_IP="192.0.2.1"
  C_name="Neigh_2"
  ```

4. Configure a cron task to finally configure the digest. Edit your **/etc/crontab** file and add the following line:
  
  ```
  30 2 * * * root /opt/BGP-sensor.awk 
  ```
