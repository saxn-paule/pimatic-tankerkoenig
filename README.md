# General information
This plugin provides actual price information for the gas station(s) of your choice. 

# Requirements
- At first you need a key from https://creativecommons.tankerkoenig.de/
- Then find your gas station IDs via the list API with your geo coordinates and the desired radius e.g.
- https://creativecommons.tankerkoenig.de/json/list.php?lat=52.521&lng=13.438&rad=5.0&sort=dist&type=all&apikey=00000000-0000-0000-0000-000000000002



# Configuration
There are three two configuration parameters
* ids - The ids of your gas station(s) separated by comma (,)
* interval - refresh interval in minutes (minimum is 5 minutes due to license regulation)
* type - Which type do you want to see (e5 | e10 | diesel | all) separated by comma (,)


### Sample Device Config:
```javascript
    {
      "id": "prices",
      "name": "prices",
      "class": "TankerkoenigDevice",
      "ids": "474e5046-deaf-4f9b-9a32-9797b778f047,4429a7d9-fb2d-4c29-8cfe-2ca90323f9f8,278130b1-e062-4a0f-80cc-19e486b4c024",
      "interval": "10",
      "type": "all"
    },
```

# Beware
This plugin is in an early alpha stadium and you use it on your own risk.
I'm not responsible for any possible damages that occur on your health, hard- or software.

# License
MIT
