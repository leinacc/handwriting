#!/usr/bin/env python3

import sys

import numpy as np
import tensorflow as tf

mnist = tf.keras.datasets.mnist

(x_train, y_train), (x_test, y_test) = mnist.load_data()

# Get all but the lightest pixels in each image
for i, img in enumerate(x_train):
    mid = np.percentile(img[img != 0], 30)
    x_train[i] = np.where(img > mid, 1, 0)
for i, img in enumerate(x_test):
    mid = np.percentile(img[img != 0], 30)
    x_test[i] = np.where(img > mid, 1, 0)

# Prep in/out for Sequential model
y_train = tf.keras.utils.to_categorical(y_train)
y_test = tf.keras.utils.to_categorical(y_test)
x_train = x_train.reshape(
    x_train.shape[0], x_train.shape[1], x_train.shape[2], 1
)
x_test = x_test.reshape(
    x_test.shape[0], x_test.shape[1], x_test.shape[2], 1
)

# Create, process, and evaluate the model
model = tf.keras.models.Sequential([
    tf.keras.layers.MaxPooling2D(pool_size=(2, 2)),
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dense(16, activation="relu"),
    tf.keras.layers.Dense(10, activation="softmax")
])

model.compile(
    optimizer="adam",
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)
model.fit(x_train, y_train, epochs=100)

model.evaluate(x_test, y_test, verbose=2)

if len(sys.argv) == 2:
    filename = sys.argv[1]
    model.save(filename)
    print(f"Model saved to {filename}.")
