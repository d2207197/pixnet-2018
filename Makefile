ifdef TEST
	pixfood20_path := $(realpath testset)
else
	pixfood20_path := $(realpath dataset/pixfood20/images)
endif

cats := $(wildcard $(pixfood20_path)/*)

cat_path := $(pixfood20_path)/$(CAT)
cat_images_path := $(cat_path)/食物
cat_masked_path := $(cat_path)/masked
cat_croped_path := $(cat_path)/croped

ifdef TEST
	cat_croped := $(wildcard $(cat_croped_path)/*)
else
	cat_images := $(wildcard $(cat_images_path)/*)
	cat_croped := $(patsubst $(cat_images_path)/%,$(cat_croped_path)/%,$(cat_images))
endif

cat_masked := $(patsubst $(cat_croped_path)/%,$(cat_masked_path)/%,$(cat_croped))

TEST_PATH := downloads/$(CAT)
TEST_MASKED_PATH := generative_inpainting/data/testset/$(CAT)/masked
TEST_CROPED_PATH := generative_inpainting/data/testset/$(CAT)/croped

inpaint_yml := config/inpaint.$(CAT).yml
image_mask := mask.jpg


test_images := $(wildcard $(TEST_PATH)/*)
test_croped := $(patsubst $(TEST_PATH)/%,$(TEST_CROPED_PATH)/%,$(test_images))
test_masked := $(patsubst $(TEST_PATH)/%,$(TEST_MASKED_PATH)/%,$(test_images))

all: croped flist masked

masked: $(cat_masked)

croped: $(cat_croped)

generate-testset: download-dataset test-masked

download-dataset:
	googleimagesdownload -k "$(CAT)" -l 30 -f jpg 
	python rename_file.py $(CAT)

test-croped: $(test_croped)

test-masked: $(test_masked)

$(TEST_CROPED_PATH)/%: $(TEST_PATH)/%
	@mkdir -p `dirname $@`
	convert '$<'  -resize 256x256^ -gravity center -crop 256x256+0+0 '$@'

$(TEST_MASKED_PATH)/%: $(TEST_CROPED_PATH)/%
	@mkdir -p `dirname $@`
	convert '$<' -fill White -draw 'rectangle 64,64 192,128' '$@'

$(cat_croped_path)/%: $(cat_images_path)/%
	@mkdir -p `dirname $@`
	convert '$<'  -resize 256x256^ -gravity center -crop 256x256+0+0 '$@'

$(cat_masked_path)/%: $(cat_croped_path)/%
	mkdir -p `dirname '$@'`
	P='$@'; convert '$<' -fill 'rgb(0,255,0)'  -draw 'rectangle 64,64 192,128' $${P%.*}.png

flist: croped
	mkdir -p 'generative_inpainting/data/pixfood20/${CAT}'
	python prepare_dataset.py \
		--folder_path `realpath '$(cat_croped_path)'` \
		--train_filename 'generative_inpainting/data/pixfood20/${CAT}/train.flist' \
		--validation_filename 'generative_inpainting/data/pixfood20/${CAT}/valid.flist'

.ONESHELL:
inpaint-yml:
	mkdir -p config
	sed 's/<CAT>/$(CAT)/g' inpaint.yml.pixfood20.template > $(inpaint_yml)

.ONESHELL:
train: 
	cd generative_inpainting/
	python train.py ../$(inpaint_yml)


ifdef POS:
	random_masked_image := $(shell echo $(cat_masked) | xargs -n1 echo | tail -n +$(POS) | head -1 )
else
	random_masked_image := $(shell shuf -e $(cat_masked) | head -1)
endif

.ONESHELL:
test: masked
	cd generative_inpainting/
	../tools/imgcat $(random_masked_image)
	python test.py --image $(random_masked_image) --mask $(image_mask)  --output out.jpg --checkpoint $(MODEL_LOG)
	../tools/imgcat out.jpg


.ONESHELL:
image-mask:
	cd generative_inpainting/
	convert -size 256x256 xc:Black -fill White -draw 'rectangle 64,64 192,128' $(image_mask)

debug:
	$(info cats="$(cats)")
	$(info cat_images_path="$(cat_images_path)")
	$(info cat_images="$(cat_images)")
	$(info cat_croped="$(cat_croped)") @true


debug-%:
	$(info $* is a $(flavor $*) variable set to [$($*)]) @true


