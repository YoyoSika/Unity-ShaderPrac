using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
public class TestDrone : MonoBehaviour {
  private const float lowPassFilterFactor = 0.05f;
  Quaternion rotation;
  public Text x, y, z;
  public Slider s_x, s_y, s_z;

  void Start()
  {
    //设置设备陀螺仪的开启/关闭状态，使用陀螺仪功能必须设置为 true
    Input.gyro.enabled = true;
    //获取设备重力加速度向量
    Vector3 deviceGravity = Input.gyro.gravity;
    //设备的旋转速度，返回结果为x，y，z轴的旋转速度，单位为（弧度/秒）
    Vector3 rotationVelocity = Input.gyro.rotationRate;
    //获取更加精确的旋转
    Vector3 rotationVelocity2 = Input.gyro.rotationRateUnbiased;
    //设置陀螺仪的更新检索时间，即隔 0.1秒更新一次
    Input.gyro.updateInterval = lowPassFilterFactor;
    //获取移除重力加速度后设备的加速度
    Vector3 acceleration = Input.gyro.userAcceleration;
    rotation = transform.rotation;
  }

	void Update () {
    transform.Rotate(-Input.gyro.rotationRateUnbiased.x * s_x.value, -Input.gyro.rotationRateUnbiased.y * s_y.value, -Input.gyro.rotationRateUnbiased.z * s_z.value);
    x.text = string.Format("X : {0:0.000}", Input.gyro.rotationRateUnbiased.x * 1000 * s_x.value);
    y.text = string.Format("Y : {0:0.000}", Input.gyro.rotationRateUnbiased.y * 1000 * s_y.value);
    z.text = string.Format("Z : {0:0.000}", Input.gyro.rotationRateUnbiased.z * 1000 * s_z.value);
	}
  public void Reset()
  {
    transform.rotation = rotation;
  }

}
