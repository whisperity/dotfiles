docker stop distcc-worker
docker rm distcc-worker

# Allow 4G mount under /tmp.
docker run \
	--name distcc-worker \
	-d \
	-p 15166:3632 \
	--restart unless-stopped \
	--mount type=tmpfs,destination=/tmp,tmpfs-size=4294967295,tmpfs-mode=1770 \
	distcc \
		-j 12
