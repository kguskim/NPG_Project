# 필요 라이브러리 설치
# pip install tensorflow opencv-python requests numpy
# pip install pytesseract

# import
import cv2
import torch
import numpy as np
import datetime 
from ultralytics import YOLO
import pytesseract # 유통기한 추출 시
import requests # 인터넷 통신 시

# 모델 로드 / 사전 학습, 커스텀 모델 경로 또한 가능
model = YOLO("")

# 매핑 - 표준화 사전
name_map = {}
calorie_map = {}

# 저장폴더,경로 생성 및 설정정
os.makedirs("detected_ingredients", exist_ok=True)

# 메타데이터 함수 생성
def get_metadata(name):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")    # 날짜 정보 기록록
    std_name = name_map.get(name, name)    # name_map> 이름 표준화 dict - 임시, 데이터 없으면 그대로 사용
    calorie = calorie_map.get(std_name, "칼로리 정보 없음")    # 데이터 없으면 문자 출력
    expiration = extract_expiration(expiration_text)
    return {
        "식재료명":std_name, 
        "날짜":now, 
        "칼로리": calorie, 
        "소비기한":expiration
        }

# ocr을 통해 소비기한 추출하는 함수
def extract_expiration(text):
    import re
    pattern =r"(20[0-9]{2})[-./년 ]?(0[1-9]|1[0-2])[-./월 ]?(0[1-9]|[12][0-9]|3[01])"
    match = re.search(pattern, text)
    if match:
        return f"{match.group(1)}-{match.group(2)}-{match.group(3)}"
    return "소비기한 추출 실패"

# 카메라 시작
cam = cv2.VideoCapture(0)

# ret> 영상 읽혔는지 boolean, false 시 종료
while True:
    # frame> numpy 배열 형식의 이미지 데이터터
    ret, frame = cap.read()
    if not ret:
        break
    
    # yolo 모델 추론 - 객체 탐지 수행
    results = model(frame)

    for box in results[0].boxes:
        class_id = int(box.cls[0])    # 사물 이름 apple, strawberry 등
        name = model.names[class_id]    # yolo 모델에 등록된 id - 이름
        
        # 박스 좌표 > 이미지 자르기
        xyxy = box.xyxy[0].cpu().numpy().astype(int)
        x1, y1, x2, y2 = xyxy
        crop_img = frame[y1:y2, x1:x2]

        # 이미지 저장
        filename = f"{name}_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        path = os.path.join("detected_ingredients", filename)
        cv2.imwrite(path, crop_img)

        # ocr 유통기한 텍스트
        ocr_text = pytesseract.image_to_string(crop_img, lang='eng+kor')
        print("[OCR]", ocr_text)

        data = get_metadata(name, ocr_text)    # 생성한 함수에 넘겨 추가 정보를 받아옴
        print(data) # -- 개발자 디버깅용
    if cv2.waitKey(1) & 0xFF == 27    # 27 = esc
        break

cam.release()
cv2.destroyAllWindows()

# -- 모바일 형식으로 수정해야함