docker stop distcc-worker
docker rm distcc-worker

MEMORY=$(expr $(expr $(free -g | head -n 2 | tail -n 1 | awk '{print $2;}') + 1) / 2)
echo "Spawned image will use ${MEMORY} GiB of /tmp for execution..."

docker run \
	--name distcc-worker \
	-d \
	-p 3632:3632 \
	--restart unless-stopped \
	--mount type=tmpfs,destination=/tmp,tmpfs-size=${MEMORY}G,tmpfs-mode=1770 \
	distcc \
		-j $(expr $(nproc) - 2)
