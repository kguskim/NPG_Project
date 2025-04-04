import cv2
import tensorflow as tf
import numpy as np

#모델 로드
model = tf.keras.applications.MobileNetV2(weights='imagenet')

#카메라 열기
cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()

    if not ret:
        break

    # 이미지 전처리
    preprocessed_image = preprocess_image(frame)

    # 예측
    predictions = model.predict(preprocessed_image)
    decoded_predictions = tf.keras.applications.mobilenet_v2.decode_predictions(predictions, top=1)[0]
    predicted_class_name = decoded_predictions[0][1]

    # 결과 표시
    cv2.putText(frame, predicted_class_name, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
    cv2.imshow('Camera', frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
