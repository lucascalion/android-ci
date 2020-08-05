echo "Building image"
docker-compose build

echo "Running container"
docker-compose up

echo "Committing image"
docker commit -c 'ENTRYPOINT [""]' emulator lucascalion/android-ci:latest

echo "Pushing image to dockerhub"
docker push lucascalion/android-ci:latest
