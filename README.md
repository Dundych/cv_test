# CV based test faramework

> The test project shows how to use computer vision to find
> and manipulate objects on the screen. The main scripts
> "scripts/find_templates_on_img.py", "scripts/find_objs_on_img.py"
> do all cv work. The rest of ruby code is wrapper,
> for cucumber demo to easy use cv on mobile testing. (Android)

## How to run examples. Local 

- Check if templates in "templates" folder is similar to your phone OS, theme and language. Change it for actual images, make sure you save the names
- Setup Android env on PC (Java, Android SDK, ADB, etc)
- Connect android device to PC via adb, get device id (eg: ZY223FFP4M)
- Navigate to project root and run test by tag

```sh
$ cucumber features -v -t @cur DEVICE_ID=ZY223FFP4M
```

- OR test any image manually

```sh
$ python scripts/find_templates_on_img.py -t <template.png> -i <image.png> -o <result.png>
```

```sh
$ python scripts/find_objs_on_img.py -q <query.png> -t <train.png> -o <result.png>
```

## Docker

- Create custom container
```sh
$ sudo docker build . -t cv-test
```

- Run custom container in detach mode
```sh
$ sudo docker run -d -t --name cv-test --privileged \
  --network=host \
  -v /dev/bus/usb:/dev/bus/usb \
  -v $(pwd):/cv_test \
  cv-test bash
```

- Create exec session for container
```sh
$ sudo docker exec -it cv-test bash
```

- Install dependencies
```sh
$ cd /cv_test && \
  sudo bundle install && \
  pip install -r requirements.txt;
```

- Run tests
```sh
$ cd /cv_test && cucumber features -v -t @cur DEVICE_ID=ZY223FFP4M
```