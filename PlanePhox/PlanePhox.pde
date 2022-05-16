//focus of vies
float fov = 3;

//swiching camera view
boolean cameraView = true;

// create plane instance
PaperPlane pp = new PaperPlane();

// http request setting
String baseURL = "http://192.168.11.19:8080/";
String getMethod = "get?accX&accY&accZ";
String url = baseURL + getMethod;

void setup() {
	size(1600, 800, P3D);
	frameRate(100);
}

void draw() {
	background(#00bfff);
	
	perspective(PI / fov,(float)width / height, 10, 10000);
	
	// swiching view with mode function
	if (cameraView) {
		camera(150, -500, 1000,
			pp.x, pp.y, pp.z,
			0, 1, 0);
	} else {
		camera(pp.x, pp.y, pp.z - 0.1f,
			pp.nextX, pp.nextY, pp.z + pp.speed * cos(pp.rx) * cos(pp.ry),
			 - sin(pp.rz) * Sign(cos(pp.ry)), cos(pp.rz), 0);
	}
	
	pushMatrix();
	rotateX(PI / 2);
	lights();
	popMatrix();
	
	// draw plane
	fill(255);
	pp.Draw();
	
	// draw floor
	fill(0, 150, 0);
	noStroke();
	for (int i= -5; i <= 5; i++) {
		for (int j= -10; j <=  10; j++) {
			pushMatrix();
			translate(i * 200, 0, j * 200);
			box(180, 10, 180);
			popMatrix();
		}
	}
	
}

class PaperPlane {
	
	float x, y, z; //位置
	float nextX, nextY, nextZ;//次のフレーム時の位置
	float speed; //移動速度
	float rx, ry, rz; //回転
	float wx, wy, wr; //翼の位置,回転角
	float wingR = PI / 45; //翼のはばたき速度
	int mode; // 飛行機の種類
	
	PaperPlane() {
		Reset();
	}
	
	void Draw() {
		// get http response
		float[] result = new float[3];
		
		result = loadJson(); 
		/* result[0] -> x
		result[1] -> y
		result[2] -> z */
		println(result);
		
		// ==============
		// plane control
		// ==============
		
		// ascending & descending
		if (result[2] >= 3.0) {
			rx -= PI / 180f;
			
		} else if (result[2] <= -3.0) {
			rx += PI / 180f;
		} else {
			
		}
		
		// turning left/right
		// left
		if (result[0] >= 3.0) { 
			ry += PI / 360f;
			if (rz < PI / 2)
			rz += PI / 360f;
			// speed += 0.1f;     
		} 
		// right 
		else if (result[0] <= -3.0) { 
      ry -= PI / 360f;
      if (rz > - PI / 2)
      rz -= PI / 360f;
		} else { }
		
		if (keyPressed) {
			// reset
			if (key == 'r') Reset();
			
			if (key == CODED) {
				// -- accel & break -- 
				//accel
				if (keyCode == UP) speed += 0.1f;
				//break
				if (keyCode == DOWN) { if (speed > 0.1f) speed -= 0.05f; else speed = 0; }
				
			} // end of if(key == CODED)
			
			if (key == '1') mode = 1;
			if (key == '2') mode = 2;
			
		} // end of if(keyPressed){
		else {
      // keep the plane level
			if (abs(rz) < PI / 180) rz = 0;
			else if (rz > 0) rz -= PI / 90f;
			else if (rz < 0) rz += PI / 90f;
			
			if (abs(rx % PI) < PI / 180) rx = 0;
			else if (rx > 0) rx -= PI / 360f;
			else if (rx < 0) rx += PI / 360f;
		}
		
		if (abs(rx) > 2 * PI) rx = 0;
		if (abs(ry) > 2 * PI) ry = 0;
		
		// update position
		x = nextX;
		y = nextY;
		z = nextZ;
		nextX = x + speed * sin(ry);
		nextY = y + speed * sin(rx);
		nextZ = z + speed * cos(rx) * cos(ry);
		
		pushMatrix();
		translate(x, y, z);
		rotateX(rx * Sign(cos(ry)) * - 1);
		rotateY(ry);
		rotateZ(rz);
		
		switch(mode) {
			case 1:
				paperPlane();
				break;
			case 2:
				paperClane();
				break;
		}
		popMatrix();
		
	} // end of Draw()
	
	// http request
	float getAcc(JSONArray buff) {
		float[] val = new float[1];
		
		if (buff.isNull(0)) {    
			val[0] = 0.0;
		} else{
			val[0] = buff.getFloat(0);
		}
		
		return val[0];
	}
	
	float[] loadJson() {
		String getMethod = "get?accX&accY&accZ";
		String url = baseURL + getMethod;
		
		float[] accXYZ = new float[3];
		
		try {
			JSONObject jobj = loadJSONObject(url);
			JSONObject buffp = jobj.getJSONObject("buffer");
			
			JSONObject accx = buffp.getJSONObject("accX");
			JSONArray xbuff = accx.getJSONArray("buffer");
			
			JSONObject accy = buffp.getJSONObject("accY");
			JSONArray ybuff = accy.getJSONArray("buffer");
			
			JSONObject accz = buffp.getJSONObject("accZ");
			JSONArray zbuff = accz.getJSONArray("buffer");
			
			accXYZ[0] = getAcc(xbuff);
			accXYZ[1] = getAcc(ybuff);
			accXYZ[2] = getAcc(zbuff);
		}
		
		catch(Exception e) {
			e.printStackTrace();
			exit();
		}
		
		return accXYZ;
	}
	
	
	// paper plane model
	void paperPlane() {
		beginShape(TRIANGLE_FAN);
		vertex(0, 0, 0);
		vertex( -30, 5, -50);
		vertex( -5, 0, -50);
		vertex(0, 20, -50);
		vertex(5, 0, -50);
		vertex(30, 5, -50);
		endShape();
	}
	
	// Orizuru model
	void paperClane() {
		
		// flying wings
		wr += wingR * speed * 0.5f;
		if (abs(wr) > radians(30)) {
			wingR *= -1;
			wr += wingR;
		}
		
		wx = 40 * cos(wr);
		wy = 40 * sin(wr);
		
		// head
		beginShape(TRIANGLE_FAN);
		vertex(0, 0, 20);
		vertex( -2, -7, 5);
		vertex(0, -5, 2);
		vertex(2, -7, 5);
		endShape();
		
		// neck
		beginShape(QUAD_STRIP);
		vertex( -2, -7, 5);
		vertex( -3, 10, -2);
		vertex(0, -5, 2);
		vertex(0, 7, -4);
		vertex(2, -7, 5);
		vertex(3, 10, -2);
		endShape();
		
		// body
		for (int i =-  1; i <=  1; i += 2) {
			beginShape(QUAD_STRIP);
			vertex(0, 17, -7);
			vertex(0, 7, -4);
			vertex(3 * i, 17, -5);
			vertex(3 * i, 10, -2);
			vertex(2 * i, 17, -13);
			vertex(4 * i, 10, -13);
			vertex(3 * i, 17, -21);
			vertex(3 * i, 10, -23);
			vertex(0, 17, -20);
			vertex(0, 7, -22);
			endShape();
		}
		
		// back
		beginShape(TRIANGLE_FAN);
		vertex(0, 6, -13);
		vertex(0, 7, -4);
		vertex(3, 10, -2);
		vertex(4, 10, -13);
		vertex(3, 10, -23);
		vertex(0, 7, -22);
		vertex( -3, 10, -23);
		vertex( -4, 10, -13);
		vertex( -3, 10, -2);
		vertex(0, 7, -4);
		endShape();
		
		// stomach
		beginShape(TRIANGLE_FAN);
		vertex(0, 17, -13);
		vertex(0, 17, -7);
		vertex(3, 17, -5);
		vertex(2, 17, -13);
		vertex(3, 17, -21);
		vertex(0, 17, -20);
		vertex( -3, 17, -21);
		vertex( -2, 17, -13);
		vertex( -3, 17, -5);
		vertex(0, 17, -7);
		endShape();
		
		// tail
		beginShape(TRIANGLE_FAN);
		vertex(0, -10, -30);
		vertex(3, 10, -23);
		vertex(0, 7, -22);
		vertex( -3, 10, -22);
		endShape();
		
		// wings
		for (int i =-  1; i <=  1; i += 2) {
			pushMatrix();
			translate(0, 10, 0);
			beginShape(TRIANGLE_FAN);
			vertex(wx * i, wy, -13);
			vertex(3 * i, 0, -2);
			vertex(4 * i, 0, -13);
			vertex(3 * i, 0, -23);
			endShape();
			popMatrix();
		}
		
	}
	
	void Reset() {
		rx = ry = rz = speed = wy = wr = 0;
		wx = 30;
		nextX = 0;
		nextY = -300;
		nextZ = -1000;
		mode = 1;
	}
	
}

float Sign(float a) {
	if (a > 0) return 1;
	else if (a < 0) return - 1;
	else return 0;
}

void keyPressed() {
	if (key == CODED) {
		// switching FoV & Camera view
		// FoV
		if (key == RIGHT) { if (fov == 18) fov = 3; else fov = 18; }
		// camera view
		if (key == LEFT) { cameraView = !cameraView; }
		
		println(key);
	}
}