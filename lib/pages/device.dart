// ignore: unnecessary_import
import 'dart:async';
// ignore: unnecessary_import
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
// import 'package:get/get.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'dart:math' as math;

// import '../main.dart';
import '../bluetooth.dart';
import 'home.dart';

double map(double value, double fromLow, double fromHigh, double toLow,
    double toHigh) {
  return toLow + (value - fromLow) * (toHigh - toLow) / (fromHigh - fromLow);
}

double maxSpeed = 1023;
bool invertX = false;
bool invertY = false;
bool lockAxes = false;
double leftMotorOffset = 50;
void send(x, y) {
  double left = x + y;
  double right = -x + y;

  print((left, right));

  double startT = 350;
  double maxT = 1;

  double mLeft = 0;
  double mRight = 0;
  if (left > 0) {
    mLeft = map(left, 0, maxT, startT, maxSpeed) - leftMotorOffset;
  } else {
    mLeft = map(left, -maxT, 0, -maxSpeed, -startT) + leftMotorOffset;
  }
  if (right > 0) {
    mRight = map(right, 0, maxT, startT, maxSpeed);
  } else {
    mRight = map(right, -maxT, 0, -maxSpeed, -startT);
  }

  BtController().controlP("${mLeft.toInt()}x${mRight.toInt()}");

  print((mLeft, mRight));
}

class JoystickControl extends StatefulWidget {
  const JoystickControl({super.key});

  @override
  State<JoystickControl> createState() => _JoystickControlState();
}

class _JoystickControlState extends State<JoystickControl> {
  JoystickMode _joystickMode = JoystickMode.all;
  double turnSpeed = 50;
  late TextEditingController lmC;

  @override
  void initState() {
    lmC = TextEditingController(text: leftMotorOffset.toString());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 50, 0, 0),
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 70),
            Transform.scale(
              scale: 1.5,
              child: Joystick(
                  mode: _joystickMode,
                  listener: (details) {
                    setState(() {
                      double x = details.x; //invert left/right
                      if (x > 0) {
                        x = map(x, 0, 1, 0, (turnSpeed / 100));
                      } else {
                        x = map(x, -1, 0, -(turnSpeed / 100), 0);
                      }
                      double y = details.y; //invert forward/backward
                      if (invertX) {
                        x = x * -1;
                      }
                      if (!invertY) {
                        y = y * -1;
                      }
                      if (x == 0 && y == 0) {
                        BtController().controlP("0x0");
                        return;
                      }
                      send(x, y);
                    });
                  }),
            ),
            const Spacer(),
            Column(
              children: [
                SizedBox(
                  width: 180,
                  height: 50,
                  child: CheckboxListTile(
                      title: const Text("Invert X"),
                      value: invertX,
                      onChanged: (value) {
                        setState(() {
                          invertX = value!;
                        });
                      }),
                ),
                SizedBox(
                  width: 180,
                  height: 50,
                  child: CheckboxListTile(
                      title: const Text("Invert Y"),
                      value: invertY,
                      onChanged: (value) {
                        setState(() {
                          invertY = value!;
                        });
                      }),
                ),
                SizedBox(
                  width: 180,
                  height: 50,
                  child: CheckboxListTile(
                      title: const Text("Lock Axes"),
                      value: lockAxes,
                      onChanged: (value) {
                        lockAxes = value!;
                        if (lockAxes) {
                          _joystickMode = JoystickMode.horizontalAndVertical;
                        } else {
                          _joystickMode = JoystickMode.all;
                        }
                        setState(() {
                          lockAxes = value;
                        });
                      }),
                ),
              ],
            ),
            const Spacer(),
            Column(
              children: [
                Row(
                  children: [
                    const Text("Speed Control"),
                    Slider(
                      min: 350,
                      max: 1023,
                      value: maxSpeed,
                      onChanged: (value) {
                        setState(() {
                          maxSpeed = value;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Turn Speed"),
                    Slider(
                      min: 0,
                      max: 100,
                      value: turnSpeed,
                      onChanged: (value) {
                        setState(() {
                          turnSpeed = value;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Left motor -"),
                    // Slider(
                    //   min: 0,
                    //   max: 100,
                    //   value: turnSpeed,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       turnSpeed = value;
                    //     });
                    //   },
                    // ),
                    const SizedBox(
                      width: 20,
                    ),
                    SizedBox(
                      width: 90,
                      height: 40,
                      child: TextFormField(
                        keyboardType: TextInputType.number,

                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          counterText: '',
                          contentPadding: EdgeInsets.all(10),
                        ),
                        // initialValue: "50",
                        maxLength: 5,
                        controller: lmC,
                        onChanged: (value) {
                          // Update variable when text changes
                          setState(() {
                            double? val = double.tryParse(value);
                            if (val! > 1023) {
                              value = "1023";
                              lmC.text = value;
                            } else if (val < -1023) {
                              value = "-1023";
                              lmC.text = value;
                            }
                            leftMotorOffset = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(width: 50),
          ],
        ),
      ),
    );
  }
}

class AccelControl extends StatefulWidget {
  const AccelControl({super.key});

  @override
  State<AccelControl> createState() => _AccelControlState();
}

class _AccelControlState extends State<AccelControl> {
  late StreamSubscription<AccelerometerEvent> acelDataStream;
  bool started = false;
  int sendSkip = 0;
  bool enabled = false;

  bool calibration = false;
  double calX = 0;
  double calY = 0;

  double easeTrun = 4;

  double yMax = 30; //max is 1 (divided by 100)
  double xMax = 100; //max is also 1 (divided by 100)

  @override
  void initState() {
    super.initState();
  }

  void startListening() {
    if (started) {
      return;
    }
    started = true;
    enabled = true;
    acelDataStream =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      if (enabled) {
        if (calibration) {
          print("calibrating");
          calX = event.x;
          calY = event.y;
          print(("calibration finished", calX, calY));
          calibration = false;
        }
        double rawX = event.x - calX;
        double rawY = event.y - calY;
        sendSkip += 1;
        if (sendSkip > 5) {
          late double x;
          late double y;

          double deadZone = 1.5;

          double xMaxH = xMax / 100;
          double yMaxH = yMax / 100;

          if (rawY < -deadZone) {
            y = map(rawY, -easeTrun, -deadZone, -yMaxH, 0);
          } else if (rawY > deadZone) {
            y = map(rawY, deadZone, easeTrun, 0, yMaxH);
          }
          if (rawX < -deadZone) {
            x = map(rawX, -10, -deadZone, -xMaxH, 0) * -1;
          } else if (rawX > deadZone) {
            x = map(rawX, deadZone, 10, 0, xMaxH) * -1;
          }

          if (rawX > -deadZone && rawX < deadZone) {
            x = 0;
          }
          if (rawY > -deadZone && rawY < deadZone) {
            y = 0;
          }
          bool sendNow = true;
          if (x == 0 && y == 0) {
            BtController().controlP("0x0");
            sendNow = false;
          }

          if (sendNow) {
            send(y, x);
          }
          sendSkip = 0;
          print((x, y));
        }
      }
    });
  }

  void stopListening() {
    if (!started) {
      return;
    }
    BtController().controlP("0x0");
    started = false;
    enabled = false;
    acelDataStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Center(
              child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      startListening();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                      minimumSize: const Size(100, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    child: const Text(
                      "Start",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      stopListening();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                      minimumSize: const Size(100, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    child: const Text(
                      "Stop",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      calibration = true;
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                      minimumSize: const Size(100, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    child: const Text(
                      "Calibrate",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Spacer(),
                  const Text("Ease Turn"),
                  Slider(
                    min: 0,
                    max: 10,
                    value: easeTrun,
                    onChanged: (value) {
                      setState(() {
                        easeTrun = value;
                      });
                    },
                  ),
                  const Spacer()
                ],
              ),
              Row(
                children: [
                  const Spacer(),
                  const Text("Left/Right Max"),
                  Slider(
                    min: 0,
                    max: 100,
                    value: yMax,
                    onChanged: (value) {
                      setState(() {
                        yMax = value;
                      });
                    },
                  ),
                  const Spacer()
                ],
              ),
              Row(
                children: [
                  const Spacer(),
                  const Text("Forward/Backward Max"),
                  Slider(
                    min: 0,
                    max: 100,
                    value: xMax,
                    onChanged: (value) {
                      setState(() {
                        xMax = value;
                      });
                    },
                  ),
                  const Spacer()
                ],
              ),
            ],
          )),
        ],
      ),
    );
  }
}

class StrWheel extends StatefulWidget {
  const StrWheel({super.key});

  @override
  State<StrWheel> createState() => _StrWheelState();
}

class _StrWheelState extends State<StrWheel> {
  double angle = 0;
  double speed = 0.0;
  static const double maxSpeed = 100.0;
  double speedChange = 500;
  double turnSpeed = 10;
  double accelerationRate = 1;
  double decelerationRate = 1;
  bool gasPedalPressed = false;
  bool brakePedalPressed = false;

  Timer? accelerationTimer;
  Timer? decelerationTimer;

  int skip = 0;

  void sendData() {
    double y = map(speed, -100, 100, -1, 1);
    double x = map(angle, -1, 1, -(turnSpeed / 100), (turnSpeed / 100));
    send(x, y);
  }

  void increaseSpeed() {
    accelerationTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        accelerationRate = speedChange / 400;
        if (speed < maxSpeed) {
          speed = (speed + accelerationRate).clamp(-maxSpeed, maxSpeed);
          sendData();
        }
      });
    });
  }

  void decreaseSpeed() {
    decelerationTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        decelerationRate = speedChange / 400;
        if (speed > -maxSpeed) {
          speed = (speed - decelerationRate).clamp(-maxSpeed, maxSpeed);
          sendData();
        }
      });
    });
  }

  void stopAcceleration() {
    accelerationTimer?.cancel();
  }

  void stopDeceleration() {
    decelerationTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          const SizedBox(width: 30),
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                double maxAngle = 1.7;
                angle += details.delta.dx / 100;
                angle = angle.clamp(-maxAngle, maxAngle);
                print(angle);

                skip += 1;
                if (skip > 35) {
                  sendData();
                  skip = 0;
                }
              });
            },
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
              child: Transform.rotate(
                angle: angle,
                child: Image.asset('lib/assets/wheel.png'),
              ),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              const Text("Accel. Speed"),
              Slider(
                min: 100,
                max: 3000,
                value: speedChange,
                onChanged: (value) {
                  setState(() {
                    speedChange = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text("Turn Speed"),
              Slider(
                min: 1,
                max: 30,
                value: turnSpeed,
                onChanged: (value) {
                  setState(() {
                    turnSpeed = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  angle = 0;
                  speed = 0;
                  BtController().controlP("0x0");
                  _StrWheelState().setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                  minimumSize: const Size(100, 50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: const Text(
                  "Stop",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Speed: $speed'),
                Row(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTapDown: (_) {
                        stopDeceleration();
                        increaseSpeed();
                      },
                      onTapUp: (_) {
                        stopAcceleration();
                      },
                      child: Container(
                        width: 100,
                        height: 200,
                        color: Colors.green,
                        child: const Center(
                          child: Text('Gas'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTapDown: (_) {
                        stopAcceleration();
                        decreaseSpeed();
                      },
                      onTapUp: (_) {
                        stopDeceleration();
                      },
                      child: Container(
                        width: 100,
                        height: 200,
                        color: Colors.red,
                        child: const Center(
                          child: Text('Brake'),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 30),
        ],
      ),
    );
  }
}

class Manual extends StatefulWidget {
  const Manual({super.key});

  @override
  State<Manual> createState() => _ManualState();
}

String forwardLeftMotor = "950";
String forwardRightMotor = "1023";
String backwardLeftMotor = "-950";
String backwardRightMotor = "-1023";
String leftLeftMotor = "600";
String leftRightMotor = "1023";
String rightLeftMotor = "900";
String rightRightMotor = "600";
String manualLeftMotor = "0";
String manualRightMotor = "0";

class _ManualState extends State<Manual> {
  late TextEditingController fLMC;
  late TextEditingController fRMC;
  late TextEditingController bLMC;
  late TextEditingController bRMC;
  late TextEditingController lLMC;
  late TextEditingController lRMC;
  late TextEditingController rLMC;
  late TextEditingController rRMC;
  late TextEditingController mLMC;
  late TextEditingController mRMC;

  @override
  void initState() {
    fLMC = TextEditingController(text: forwardLeftMotor);
    fRMC = TextEditingController(text: forwardRightMotor);
    bLMC = TextEditingController(text: backwardLeftMotor);
    bRMC = TextEditingController(text: backwardLeftMotor);
    lLMC = TextEditingController(text: leftLeftMotor);
    lRMC = TextEditingController(text: leftRightMotor);
    rLMC = TextEditingController(text: rightLeftMotor);
    rRMC = TextEditingController(text: rightRightMotor);
    mLMC = TextEditingController(text: manualLeftMotor);
    mRMC = TextEditingController(text: manualRightMotor);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          const SizedBox(width: 30),
          Column(
            children: [
              //FORWARD
              ElevatedButton(
                onPressed: () {
                  String str = "${forwardLeftMotor}x$forwardRightMotor";
                  BtController().controlP(str);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                  minimumSize: const Size(230, 50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: const Text(
                  "Forward",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 10),
              Form(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                        contentPadding: EdgeInsets.all(10),
                      ),
                      controller: fLMC,
                      // initialValue: "950",
                      maxLength: 5,
                      maxLines: 1,
                      onChanged: (value) {
                        setState(() {
                          double val = double.parse(value);
                          if (val > 1022) {
                            value = "1023";
                            fLMC.text = value;
                          } else if (val < -1022) {
                            value = "-1023";
                            fLMC.text = value;
                          }
                          forwardLeftMotor = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                        contentPadding: EdgeInsets.all(10),
                      ),
                      // initialValue: "1023",
                      controller: fRMC,
                      maxLength: 5,
                      maxLines: 1,
                      onChanged: (value) {
                        setState(() {
                          double val = double.parse(value);
                          if (val > 1022) {
                            value = "1023";
                            fRMC.text = value;
                          } else if (val < -1022) {
                            value = "-1023";
                            fRMC.text = value;
                          }
                          forwardRightMotor = value;
                        });
                      },
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 40),

              //LEFT
              ElevatedButton(
                onPressed: () {
                  String str = "${leftLeftMotor}x$leftRightMotor";
                  BtController().controlP(str);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                  minimumSize: const Size(230, 50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: const Text(
                  "Left",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                        contentPadding: EdgeInsets.all(10),
                      ),
                      // initialValue: "600",
                      controller: lLMC,
                      maxLength: 5,
                      maxLines: 1,
                      onChanged: (value) {
                        setState(() {
                          double val = double.parse(value);
                          if (val > 1022) {
                            value = "1023";
                            lLMC.text = value;
                          } else if (val < -1022) {
                            value = "-1023";
                            lLMC.text = value;
                          }
                          leftLeftMotor = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                        contentPadding: EdgeInsets.all(10),
                      ),
                      // initialValue: "1023",
                      controller: lRMC,
                      maxLength: 5,
                      maxLines: 1,
                      onChanged: (value) {
                        setState(() {
                          double val = double.parse(value);
                          if (val > 1022) {
                            value = "1023";
                            lRMC.text = value;
                          } else if (val < -1022) {
                            value = "-1023";
                            lRMC.text = value;
                          }
                          leftRightMotor = value;
                        });
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(width: 50),
          Row(
            children: [
              Column(
                children: [
                  //BACKWARD
                  ElevatedButton(
                    onPressed: () {
                      String str = "${backwardLeftMotor}x$backwardRightMotor";
                      BtController().controlP(str);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                      minimumSize: const Size(230, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    child: const Text(
                      "Backward",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 40,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            counterText: '',
                            contentPadding: EdgeInsets.all(10),
                          ),
                          // initialValue: "-950",
                          controller: bLMC,
                          maxLength: 5,
                          maxLines: 1,
                          onChanged: (value) {
                            setState(() {
                              double val = double.parse(value);
                              if (val > 1022) {
                                value = "1023";
                                bLMC.text = value;
                              } else if (val < -1022) {
                                value = "-1023";
                                bLMC.text = value;
                              }
                              backwardLeftMotor = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        height: 40,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            counterText: '',
                            contentPadding: EdgeInsets.all(10),
                          ),
                          // initialValue: "-1023",
                          controller: bRMC,
                          maxLength: 5,
                          maxLines: 1,
                          onChanged: (value) {
                            setState(() {
                              double val = double.parse(value);
                              if (val > 1022) {
                                value = "1023";
                                bRMC.text = value;
                              } else if (val < -1022) {
                                value = "-1023";
                                bRMC.text = value;
                              }
                              backwardRightMotor = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  //RIGHT
                  ElevatedButton(
                    onPressed: () {
                      String str = "${rightLeftMotor}x$rightRightMotor";
                      BtController().controlP(str);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                      minimumSize: const Size(230, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    child: const Text(
                      "Right",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 40,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            counterText: '',
                            contentPadding: EdgeInsets.all(10),
                          ),
                          // initialValue: "900",
                          controller: rLMC,
                          maxLength: 5,
                          maxLines: 1,
                          onChanged: (value) {
                            setState(() {
                              double val = double.parse(value);
                              if (val > 1022) {
                                value = "1023";
                                rLMC.text = value;
                              } else if (val < -1022) {
                                value = "-1023";
                                rLMC.text = value;
                              }
                              rightLeftMotor = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        height: 40,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            counterText: '',
                            contentPadding: EdgeInsets.all(10),
                          ),
                          // initialValue: "600",
                          controller: rRMC,
                          maxLength: 5,
                          maxLines: 1,
                          onChanged: (value) {
                            setState(() {
                              double val = double.parse(value);
                              if (val > 1022) {
                                value = "1023";
                                rRMC.text = value;
                              } else if (val < -1022) {
                                value = "-1023";
                                rRMC.text = value;
                              }
                              rightRightMotor = value;
                            });
                          },
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
          const Spacer(),
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  String str = "${manualLeftMotor}x$manualRightMotor";
                  BtController().controlP(str);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                  minimumSize: const Size(230, 50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: const Text(
                  "Send",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                        contentPadding: EdgeInsets.all(10),
                      ),
                      // initialValue: "0",
                      controller: mLMC,
                      maxLength: 5,
                      maxLines: 1,
                      onChanged: (value) {
                        setState(() {
                          double val = double.parse(value);
                          if (val > 1022) {
                            value = "1023";
                            mLMC.text = value;
                          } else if (val < -1022) {
                            value = "-1023";
                            mLMC.text = value;
                          }
                          manualLeftMotor = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: '',
                        contentPadding: EdgeInsets.all(10),
                      ),
                      // initialValue: "0",
                      controller: mRMC,
                      maxLength: 5,
                      maxLines: 1,
                      onChanged: (value) {
                        setState(() {
                          double val = double.parse(value);
                          if (val > 1022) {
                            value = "1023";
                            mRMC.text = value;
                          } else if (val < -1022) {
                            value = "-1023";
                            mRMC.text = value;
                          }
                          manualRightMotor = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  BtController().controlP("0x0");
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                  minimumSize: const Size(350, 150),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: const Text(
                  "STOP",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(width: 30),
        ],
      ),
    );
  }
}

class More extends StatefulWidget {
  const More({super.key});

  @override
  State<More> createState() => _MoreState();
}

class _MoreState extends State<More> {
  late TextEditingController macChange;
  @override
  void initState() {
    macChange = TextEditingController(text: predefinedMAC);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 160,
      child: SingleChildScrollView(
        child: Row(
          children: [
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("Source code: ", style: TextStyle(fontSize: 20)),
                    InkWell(
                      onTap: () => launchUrl(
                          Uri.parse('https://github.com/Sucharek233/DIYRCBLE')),
                      child: const Text(
                        'https://github.com/Sucharek233/DIYRCBLE',
                        style: TextStyle(color: Colors.blue, fontSize: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  "Value send format: leftMotorValuexRightMotorValue (for example 500x1023)\nMinimum value: -1023      Maximum value: 1023",
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text(
                        "Sending to service: 6e400001-b5a3-f393-e0a9-e50e24dcca9e\nand characteristic: 6e400002-b5a3-f393-e0a9-e50e24dcca9e",
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 30),
                    Column(
                      children: [
                        ElevatedButton(
                            onPressed: () async {
                              ClipboardData data = const ClipboardData(
                                  text: '6e400001-b5a3-f393-e0a9-e50e24dcca9e');
                              await Clipboard.setData(data);
                            },
                            child: const Text("Copy service")),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: () async {
                              ClipboardData data = const ClipboardData(
                                  text: '6e400002-b5a3-f393-e0a9-e50e24dcca9e');
                              await Clipboard.setData(data);
                            },
                            child: const Text("Copy characteristic")),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    const Text("Predefined MAC Address:",
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 300,
                      height: 42,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          counterText: '',
                          contentPadding: EdgeInsets.all(10),
                        ),
                        controller: macChange,
                        maxLines: 1,
                        onChanged: (value) {
                          predefinedMAC = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () {
                          Files().writeMAC(macChange.text);
                        },
                        child: const Text("Save")),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () {
                          if (currMAC != "") {
                            Files().writeMAC(currMAC);
                            macChange.text = currMAC;
                            predefinedMAC = currMAC;
                          }
                        },
                        child: const Text("Save connected device MAC")),
                  ],
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class Device extends StatefulWidget {
  const Device({super.key});

  @override
  State<Device> createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  Widget? _selectedWidget;
  String _selectedDropdownItem = "Joystick";

  @override
  void initState() {
    super.initState();

    BtController().discoverServices();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    _selectedWidget = const JoystickControl();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          color: const Color.fromRGBO(0, 100, 0, 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  BtController().discoverServices();
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeRight,
                    DeviceOrientation.landscapeLeft,
                  ]);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                  minimumSize: const Size(100, 50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: const Text(
                  "Reinitialize",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedDropdownItem,
                style: const TextStyle(fontSize: 18, color: Colors.black),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDropdownItem = newValue!;
                    switch (newValue) {
                      case 'Joystick':
                        _selectedWidget = const JoystickControl();
                        break;
                      case 'Accelerometer':
                        _selectedWidget = const AccelControl();
                        break;
                      case 'Steering Wheel':
                        _selectedWidget = const StrWheel();
                        break;
                      case 'Manual':
                        _selectedWidget = const Manual();
                        break;
                      case 'Info':
                        _selectedWidget = const More();
                      default:
                        _selectedWidget = null;
                    }
                  });
                },
                items: <String>[
                  'Joystick',
                  'Accelerometer',
                  'Steering Wheel',
                  'Manual',
                  'Info'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  BtController().disconnect();
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown,
                  ]);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 0, 150, 0),
                  minimumSize: const Size(100, 50),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: const Text(
                  "Disconnect",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10)
            ],
          ),
        ),
        const SizedBox(height: 25),
        _selectedWidget ?? Container(),
      ],
    ));
  }
}
